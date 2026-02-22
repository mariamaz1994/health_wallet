class ImportLabResultsController < ApplicationController
  def new
    @import_record = ImportRecord.new
  end

  def create
    if params[:file].blank?
      flash[:alert] = "You have not selected a file to upload. Please choose a file and try again."
      redirect_to action: :new
      return
    end

    uploaded_file = params[:file]
    filename = "hl7_#{Time.current.to_i}_#{uploaded_file.original_filename}"

    # Save uploaded file temporarily
    temp_file = File.join(Dir.tmpdir, filename)
    File.open(temp_file, "wb") do |file|
      file.write(uploaded_file.read)
    end

    import_record = ImportRecord.create!(
      filename: uploaded_file.original_filename,
      status: 'pending'
    )

    redirect_to action: :show, id: import_record.id, notice: "File uploaded successfully. Processing in background..."
  end

  def show
    @import_record = ImportRecord.find(params[:id])
  end
end
