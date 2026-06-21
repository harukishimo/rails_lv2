require "test_helper"
require "tempfile"
require "caxlsx"
require "zip"

class EvaluationTargetImporterTest < ActiveSupport::TestCase
  UploadedFile = Struct.new(:path, :original_filename, keyword_init: true)

  test "previews and imports csv rows with row-level errors" do
    token = SecureRandom.hex(4)
    with_upload("targets.csv", csv_content(valid_rows: 1, invalid_row: true, token: token)) do |file|
      preview = EvaluationTargets::Importer.preview(file: file)

      assert_equal :preview, preview.mode
      assert_equal 2, preview.processed_count
      assert_equal 1, preview.created_count
      assert_equal 1, preview.failed_count
      assert_includes preview.rows.last.errors, "skill_level_code is required"

      result = EvaluationTargets::Importer.import(file: file)

      assert_equal :import, result.mode
      assert_equal 1, result.created_count
      assert_equal 1, result.failed_count
      target = EvaluationTarget.find_by!(external_knowledge_key: "rails_lv2_#{token}_0")
      assert_equal "Ruby #{token} Rails #{token} Lv2 2026.06-#{token}-0", target.display_name
    end
  end

  test "imports xlsx rows" do
    token = SecureRandom.hex(4)
    with_xlsx_upload("targets.xlsx", [
      %w[skill_area programming_language framework skill_level skill_level_numeric_level external_knowledge_key version],
      [ "Backend #{token}", "Go #{token}", "", "Lv3", 3, "go_lv3_#{token}", "2026.06" ]
    ]) do |file|
      result = EvaluationTargets::Importer.import(file: file)

      assert result.success?
      assert_equal 1, result.created_count
      target = EvaluationTarget.find_by!(external_knowledge_key: "go_lv3_#{token}")
      assert_equal "Go #{token} Lv3 2026.06", target.display_name
    end
  end

  test "csv import processes many rows without requiring a preloaded array" do
    token = SecureRandom.hex(4)
    before_count = EvaluationTarget.count

    with_upload("many-targets.csv", csv_content(valid_rows: 120, token: token)) do |file|
      result = EvaluationTargets::Importer.import(file: file)

      assert result.success?
      assert_equal 120, result.created_count
      assert_equal 120, EvaluationTarget.count - before_count
    end
  end

  test "limits retained display rows while processing large csv imports" do
    token = SecureRandom.hex(4)

    with_upload("many-targets.csv", csv_content(valid_rows: EvaluationTargets::Importer::DISPLAY_ROW_LIMIT + 5, token: token)) do |file|
      result = EvaluationTargets::Importer.import(file: file)

      assert result.success?
      assert result.truncated?
      assert_equal EvaluationTargets::Importer::DISPLAY_ROW_LIMIT + 5, result.processed_count
      assert_equal EvaluationTargets::Importer::DISPLAY_ROW_LIMIT, result.rows.size
      assert_equal 5, result.truncated_count
    end
  end

  test "import updates existing target identity instead of duplicating it" do
    token = SecureRandom.hex(4)
    before_count = EvaluationTarget.count

    with_upload("target.csv", csv_content(valid_rows: 1, description: "initial", token: token)) do |file|
      EvaluationTargets::Importer.import(file: file)
    end

    with_upload("target.csv", csv_content(valid_rows: 1, description: "updated", token: token)) do |file|
      result = EvaluationTargets::Importer.import(file: file)

      assert result.success?
      assert_equal 0, result.created_count
      assert_equal 1, result.updated_count
      assert_equal 1, EvaluationTarget.count - before_count
      assert_equal "updated", EvaluationTarget.find_by!(external_knowledge_key: "rails_lv2_#{token}_0").description
    end
  end

  test "rejects oversized files before parsing" do
    with_upload("too-large.csv", "a" * (EvaluationTargets::Importer::MAX_FILE_SIZE + 1)) do |file|
      error = assert_raises(EvaluationTargets::Importer::UnsupportedFileError) do
        EvaluationTargets::Importer.preview(file: file)
      end

      assert_equal "ファイルサイズは5MB以下にしてください", error.message
    end
  end

  test "rejects corrupt xlsx files as import errors" do
    with_upload("corrupt.xlsx", "not an xlsx") do |file|
      error = assert_raises(EvaluationTargets::Importer::UnsupportedFileError) do
        EvaluationTargets::Importer.preview(file: file)
      end

      assert_equal "XLSXファイルを読み取れません", error.message
    end
  end

  test "rejects xlsx files missing required ooxml entries before roo parsing" do
    Tempfile.create([ "invalid-ooxml", ".xlsx" ]) do |file|
      Zip::File.open(file.path, create: true) do |zip|
        zip.get_output_stream("[Content_Types].xml") { |entry| entry.write("xml") }
      end

      upload = UploadedFile.new(path: file.path, original_filename: "invalid.xlsx")
      error = assert_raises(EvaluationTargets::Importer::UnsupportedFileError) do
        EvaluationTargets::Importer.preview(file: upload)
      end

      assert_equal "XLSXファイルを読み取れません", error.message
    end
  end

  test "rejects xlsx files with missing referenced worksheet before roo parsing" do
    Tempfile.create([ "invalid-worksheet", ".xlsx" ]) do |file|
      Zip::File.open(file.path, create: true) do |zip|
        zip.get_output_stream("[Content_Types].xml") { |entry| entry.write("xml") }
        zip.get_output_stream("_rels/.rels") do |entry|
          entry.write(relationships_xml("rId1" => "xl/workbook.xml"))
        end
        zip.get_output_stream("xl/workbook.xml") { |entry| entry.write("xml") }
        zip.get_output_stream("xl/_rels/workbook.xml.rels") do |entry|
          entry.write(relationships_xml("rId1" => "worksheets/missing.xml"))
        end
      end

      upload = UploadedFile.new(path: file.path, original_filename: "invalid.xlsx")
      error = assert_raises(EvaluationTargets::Importer::UnsupportedFileError) do
        EvaluationTargets::Importer.preview(file: upload)
      end

      assert_equal "XLSXファイルを読み取れません", error.message
    end
  end

  test "rejects csv data rows that exceed the column limit" do
    headers = (1..EvaluationTargets::Importer::MAX_IMPORT_COLUMNS).map { |index| "column#{index}" }
    values = (1..EvaluationTargets::Importer::MAX_IMPORT_COLUMNS + 1).map { |index| "value#{index}" }

    with_upload("too-many-columns.csv", "#{headers.join(',')}\n#{values.join(',')}\n") do |file|
      error = assert_raises(EvaluationTargets::Importer::UnsupportedFileError) do
        EvaluationTargets::Importer.preview(file: file)
      end

      assert_equal "取込列数は#{EvaluationTargets::Importer::MAX_IMPORT_COLUMNS}列以下にしてください", error.message
    end
  end

  test "rolls back imported rows when later csv parsing fails" do
    token = SecureRandom.hex(4)
    content = [
      "skill_area,programming_language,framework,skill_level,skill_level_numeric_level,external_knowledge_key,version",
      "Backend #{token},Ruby #{token},Rails #{token},Lv2,2,rails_lv2_#{token},2026.06",
      "\"broken"
    ].join("\n")

    with_upload("broken-late.csv", content) do |file|
      error = assert_raises(EvaluationTargets::Importer::UnsupportedFileError) do
        EvaluationTargets::Importer.import(file: file)
      end

      assert_equal "ファイルを読み取れません。CSV/XLSX形式と文字コードを確認してください", error.message
      assert_nil EvaluationTarget.find_by(external_knowledge_key: "rails_lv2_#{token}")
    end
  end

  test "rejects non utf8 csv files as import errors" do
    Tempfile.create([ "invalid-encoding", ".csv" ]) do |file|
      file.binmode
      file.write("\xC3\x28".b)
      file.flush

      upload = UploadedFile.new(path: file.path, original_filename: "invalid.csv")
      error = assert_raises(EvaluationTargets::Importer::UnsupportedFileError) do
        EvaluationTargets::Importer.preview(file: upload)
      end

      assert_equal "CSVはUTF-8で保存してください", error.message
    end
  end

  private

  def csv_content(valid_rows:, token: SecureRandom.hex(4), invalid_row: false, description: "description")
    lines = [
      "skill_area,programming_language,framework,skill_level,skill_level_numeric_level,external_knowledge_key,version,description,display_order,active"
    ]
    valid_rows.times do |index|
      lines << "Backend #{token},Ruby #{token},Rails #{token},Lv2,2,rails_lv2_#{token}_#{index},2026.06-#{token}-#{index},#{description},#{index},true"
    end
    lines << "Backend #{token},Ruby #{token},Rails #{token},,2,,2026.06-error,description,0,true" if invalid_row
    "#{lines.join("\n")}\n"
  end

  def with_upload(filename, content)
    Tempfile.create([ "evaluation-targets", File.extname(filename) ]) do |file|
      file.write(content)
      file.flush
      yield UploadedFile.new(path: file.path, original_filename: filename)
    end
  end

  def with_xlsx_upload(filename, rows)
    Tempfile.create([ "evaluation-targets", ".xlsx" ]) do |file|
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "targets") do |sheet|
        rows.each { |row| sheet.add_row(row) }
      end
      package.serialize(file.path)
      yield UploadedFile.new(path: file.path, original_filename: filename)
    end
  end

  def relationships_xml(targets)
    relationships = targets.map do |id, target|
      %(<Relationship Id="#{id}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="#{target}"/>)
    end.join
    %(<?xml version="1.0" encoding="UTF-8"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">#{relationships}</Relationships>)
  end
end
