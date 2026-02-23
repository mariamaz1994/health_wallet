require "test_helper"

class MedicalRecordTest < ActiveSupport::TestCase
  test "should create medical record with default values" do
    medical_record = MedicalRecord.create!(filename: "test.txt")

    assert_equal "test.txt", medical_record.filename
    assert_equal "pending", medical_record.status
    assert_equal 0, medical_record.records_processed
    assert_nil medical_record.error_message
  end

  test "should set status to processing" do
    medical_record = MedicalRecord.create!(
      filename: "test.txt",
      status: "processing"
    )

    assert_equal "processing", medical_record.status
  end

  test "should set status to completed with records processed" do
    medical_record = MedicalRecord.create!(
      filename: "test.txt",
      status: "completed",
      records_processed: 10
    )

    assert_equal "completed", medical_record.status
    assert_equal 10, medical_record.records_processed
  end

  test "should set status to failed with error message" do
    error_msg = "File not found"
    medical_record = MedicalRecord.create!(
      filename: "test.txt",
      status: "failed",
      error_message: error_msg
    )

    assert_equal "failed", medical_record.status
    assert_equal error_msg, medical_record.error_message
  end

  test "should update medical record status" do
    medical_record = MedicalRecord.create!(filename: "test.txt")
    assert_equal "pending", medical_record.status

    medical_record.update!(status: "processing")
    assert_equal "processing", medical_record.status

    medical_record.update!(status: "completed", records_processed: 5)
    assert_equal "completed", medical_record.status
    assert_equal 5, medical_record.records_processed
  end

  test "should have timestamps" do
    medical_record = MedicalRecord.create!(filename: "test.txt")

    assert_not_nil medical_record.created_at
    assert_not_nil medical_record.updated_at
  end

  test "should find medical record by id" do
    medical_record = MedicalRecord.create!(filename: "test.txt")
    found_record = MedicalRecord.find(medical_record.id)

    assert_equal medical_record.id, found_record.id
    assert_equal "test.txt", found_record.filename
  end

  test "should count medical records" do
    MedicalRecord.delete_all
    assert_equal 0, MedicalRecord.count

    MedicalRecord.create!(filename: "test1.txt")
    assert_equal 1, MedicalRecord.count

    MedicalRecord.create!(filename: "test2.txt")
    assert_equal 2, MedicalRecord.count
  end
end
