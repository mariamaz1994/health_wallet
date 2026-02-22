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
    lines = File.readlines(@file_path).map(&:strip).reject(&:empty?)
    current_patient = nil
    current_assessment = nil

    lines.each do |line|
      if patient_header?(line)
        parts = line.split("|")
        if parts.length >= 4
          current_patient = find_or_create_patient(parts[0], parts[1], parts[2])
          current_assessment = find_or_create_assessment(current_patient, parts[3])
          @records_processed += 1
        end
      elsif observation_line?(line) && current_assessment
        parts = line.split("|")
        if parts.length >= 3 && OBSERVATION_CODES.key?(parts[0])
          find_or_create_observation(current_assessment, parts[0], parts[1].to_f, parts[2])
          @records_processed += 1
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
    date_str.to_date.present?
  rescue ArgumentError
    false
  end

  def find_or_create_patient(name, dob_str, sex_at_birth)
    dob = Date.parse(dob_str)
    patient = Patient.where(name: name, dob: dob, sex_at_birth: sex_at_birth).first
    
    unless patient
      patient = Patient.create!(
        name: name,
        dob: dob,
        sex_at_birth: sex_at_birth
      )
    end

    patient
  end

  def find_or_create_assessment(patient, reference)
    assessment = patient.assessments.where(reference: reference).first

    unless assessment
      assessment = patient.assessments.create!(
        reference: reference,
        date: Time.current.to_s
      )
    end

    assessment
  end

  def find_or_create_observation(assessment, code, value, units)
    observation = assessment.observations.where(code: code).first

    if observation
      observation.update!(value: value, units: units)
    else
      assessment.observations.create!(
        code: code,
        name: OBSERVATION_CODES[code],
        value: value,
        units: units
      )
    end
  end
end
