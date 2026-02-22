class Hl7Parser
  OBSERVATION_CODES = {
    "8480-6" => "Blood Pressure (Systolic)",
    "8462-4" => "Blood Pressure (Diastolic)",
    "8867-4" => "Heart Rate",
    "8310-5" => "Body Temperature",
    "9279-1" => "Respiratory Rate",
    "2708-6" => "Oxygen Saturation",
    "29463-7" => "Body Weight",
    "8302-2" => "Body Height",
    "2339-0" => "Blood Glucose",
    "2093-3" => "Cholesterol"
  }.freeze

  def initialize(file_path)
    @file_path = file_path
    @records_processed = 0
  end

  def parse_and_import
    current_patient = nil
    current_assessment = nil

    File.foreach(@file_path) do |line|
      clean_line = line.strip
      next if clean_line.empty?

      if patient_header?(clean_line)
        parts = clean_line.split("|")
        if parts.length >= 4
          current_patient = find_or_create_patient(parts[0], parts[1], parts[2])
          current_assessment = find_or_create_assessment(current_patient, parts[3])
          @records_processed += 1 if current_assessment
        end
      elsif observation_line?(clean_line) && current_assessment
        parts = clean_line.split("|")
        if parts.length >= 3 && OBSERVATION_CODES.key?(parts[0])
          find_or_create_observation(current_assessment, parts[0], parts[1].to_f, parts[2])
        end
      end
    end

    @records_processed
  end

  private

  def patient_header?(line)
    # A patient header has at least 4 fields and the second field is a date
    parts = line.split("|")
    parts.length >= 4 && valid_date?(parts[1])
  end

  def observation_line?(line)
    # An observation has exactly 3 fields separated by pipes
    parts = line.split("|")
    parts.length == 3 && OBSERVATION_CODES.key?(parts[0])
  end

  def valid_date?(date_str)
    parsed_date = Date.strptime(date_str, '%Y-%m-%d')

    parsed_date.year.between?(1900, 2100)
  rescue ArgumentError, TypeError
    false
  end

  def find_or_create_patient(name, dob_str, sex_at_birth)
    dob = Date.strptime(dob_str, '%Y-%m-%d')
   
    Patient.find_or_create_by!(
      name: name,
      dob: dob,
      sex_at_birth: sex_at_birth
    )
  rescue ArgumentError, ActiveRecord::RecordInvalid
    nil
  end

  def find_or_create_assessment(patient, reference)
    return nil unless patient

    patient.assessments.find_or_create_by!(
      reference: reference,
      date: Time.current.to_s
    )
  end

  def find_or_create_observation(assessment, code, value, units)
    return nil unless assessment

    observation = assessment.observations.find_or_initialize_by(code: code)

    observation.update!(
      name: OBSERVATION_CODES[code],
      value: value,
      units: units
    )

    observation
  end
end
