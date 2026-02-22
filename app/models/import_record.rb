class ImportRecord
  include Mongoid::Document
  include Mongoid::Timestamps

  field :filename, type: String
  field :status, type: String, default: "pending"  # pending, processing, completed, failed
  field :error_message, type: String
  field :records_processed, type: Integer, default: 0

  store_in collection: "import_records"
end
