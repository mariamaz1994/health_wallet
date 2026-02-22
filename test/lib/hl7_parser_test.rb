require "test_helper"
require "hl7_parser"

class Hl7ParserTest < ActiveSupport::TestCase
  setup do
    @test_file = File.join(Dir.tmpdir, "test_hl7_#{Time.current.to_i}.txt")
  end

  teardown do
    File.delete(@test_file) if File.exist?(@test_file)
  end

  test "should parse single patient with observations" do
    File.write(@test_file, "John Doe|1985-03-15|M|REF-2024-001\n8480-6|120|mmHg\n8462-4|80|mmHg\n")
    
    parser = Hl7Parser.new(@test_file)
    records_count = parser.parse_and_import
    
    patient = Patient.find_by(name: "John Doe")
    assert patient
    assert_equal Date.parse("1985-03-15"), patient.dob
    assert_equal "M", patient.sex_at_birth
    
    assessment = patient.assessments.find_by(reference: "REF-2024-001")
    assert assessment
    assert_equal 2, assessment.observations.count
  end

  test "should update existing patient observation" do
    patient = Patient.create!(
      name: "Jane Smith",
      dob: Date.parse("1990-07-22"),
      sex_at_birth: "F"
    )
    assessment = patient.assessments.create!(
      reference: "REF-2024-002",
      date: Time.current.to_s
    )
    observation = assessment.observations.create!(
      code: "8480-6",
      name: "Blood Pressure (Systolic)",
      value: 100.0,
      units: "mmHg"
    )

    File.write(@test_file, "Jane Smith|1990-07-22|F|REF-2024-002\n8480-6|120|mmHg\n")
    
    parser = Hl7Parser.new(@test_file)
    records_count = parser.parse_and_import
    
    observation.reload
    assert_equal 120.0, observation.value
    assert_equal "mmHg", observation.units
  end

  test "should parse multiple patients" do
    content = "John Doe|1985-03-15|M|REF-2024-001\n"
    content += "2093-3|190|mg/dL\n"
    content += "Jane Smith|1990-07-22|F|REF-2024-002\n"
    content += "8480-6|118|mmHg\n"
    
    File.write(@test_file, content)
    
    parser = Hl7Parser.new(@test_file)
    records_count = parser.parse_and_import
    
    assert_equal 2, Patient.count
  end

  test "should only create observations with valid codes" do
    File.write(@test_file, "John Doe|1985-03-15|M|REF-2024-001\n8480-6|120|mmHg\n9999-9|999|invalid\n")
    
    parser = Hl7Parser.new(@test_file)
    records_count = parser.parse_and_import

    assessment = Patient.first.assessments.first
    assert_equal 1, assessment.observations.count
    assert_equal "8480-6", assessment.observations.first.code
  end

  test "should handle invalid date gracefully" do
    File.write(@test_file, "John Doe|19850-03-15|M|REF-2024-001\n8480-6|120|mmHg\n")

    parser = Hl7Parser.new(@test_file)
    records_count = parser.parse_and_import

    #Does not create a new patient
    assert_equal 0, Patient.count
  end

  test "should handle observations with all valid codes" do
    content = "John Doe|1985-03-15|M|REF-2024-001\n"
    content += "8480-6|120|mmHg\n"
    content += "8462-4|80|mmHg\n"
    content += "8867-4|72|bpm\n"
    content += "8310-5|98.6|°F\n"
    content += "9279-1|16|breaths/min\n"
    content += "2708-6|98|%\n"
    content += "29463-7|65.5|kg\n"
    content += "8302-2|165|cm\n"
    content += "2339-0|95|mg/dL\n"
    content += "2093-3|190|mg/dL\n"
    
    File.write(@test_file, content)
    
    parser = Hl7Parser.new(@test_file)
    records_count = parser.parse_and_import
    
    assessment = Patient.first.assessments.first
    assert_equal 10, assessment.observations.count
  end
end
