class ImportLabResultsJob < ApplicationJob
  queue_as :default

  def perform(import_record_id, file_path)
    import_record = MedicalRecord.find(import_record_id)
    import_record.update!(status: "processing")

    begin
      parser = Hl7Parser.new(file_path)
      records_processed = parser.parse_and_import
      
      import_record.update!(
        status: "completed",
        records_processed: records_processed
      )
    rescue StandardError => e
      import_record.update!(
        status: "failed",
        error_message: e.message
      )
    ensure
      # Clean up the temporary file
      File.delete(file_path) if File.exist?(file_path)
    end
  end
end
