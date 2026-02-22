require "test_helper"

class ImportLabResultsControllerTest < ActionDispatch::IntegrationTest
  test "should get new page" do
    get "/import_lab_results/new"
    assert_response :success
    assert_select "h1", "Upload Lab Results"
  end

  test "should redirect when no file selected" do
    post "/import_lab_results", params: { file: nil }
    assert_redirected_to "/import_lab_results/new"
    assert_equal "You have not selected a file to upload. Please choose a file and try again.", flash[:alert]
  end

  test "should create import record" do
    # Create a fixture file
    file_path = File.join(Rails.root, "test/fixtures/files/test_hl7.txt")
    File.write(file_path, "John Doe|1985-03-15|M|REF-2024-001\n8480-6|120|mmHg\n")

    file = fixture_file_upload("test_hl7.txt", "text/plain")

    assert_difference "ImportRecord.count", 1 do
      post "/import_lab_results", params: { file: file }
    end

    import_record = ImportRecord.last
    assert_response :redirect
    assert_equal "pending", import_record.status
    assert_equal "test_hl7.txt", import_record.filename
  ensure
    File.delete(file_path) if File.exist?(file_path)
  end
end
