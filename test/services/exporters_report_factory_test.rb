require "test_helper"
require "csv"
require "fileutils"
require "tempfile"
require "roo"

class ExportersReportFactoryTest < ActiveSupport::TestCase
  test "lists supported reports" do
    assert_equal(
      %w[evaluation_targets review_results submission_statuses user_qualifications],
      Exporters::ReportFactory.reports.map(&:key)
    )
  end

  test "exports evaluation targets as csv with spreadsheet formula sanitization" do
    create_evaluation_target(language_name: "=Ruby #{SecureRandom.hex(4)}")

    export = Exporters::ReportFactory.call(report_key: "evaluation_targets", format: "csv")

    assert_equal "text/csv; charset=utf-8", export.content_type
    assert_includes export.filename, "evaluation_targets-"
    assert_includes export.body, "技術領域"
    assert_includes export.body, "'=Ruby"
  end

  test "prepares csv downloads as an enumerable stream" do
    create_evaluation_target(language_name: "Ruby #{SecureRandom.hex(4)}")

    export = Exporters::ReportFactory.download(report_key: "evaluation_targets", format: "csv")

    assert_nil export.path
    assert_respond_to export.body, :each
    chunks = export.body.to_a
    assert chunks.first.include?("技術領域")
    assert chunks.size > 1
  end

  test "prepares xlsx downloads as a generated file path" do
    create_evaluation_target(language_name: "Ruby #{SecureRandom.hex(4)}")

    export = Exporters::ReportFactory.download(report_key: "evaluation_targets", format: "xlsx")

    assert export.file?
    assert_nil export.body
    assert File.exist?(export.path)
    assert File.binread(export.path, 2).start_with?("PK")
  ensure
    FileUtils.rm_f(export&.path)
  end

  test "sanitizes formulas after whitespace and control characters" do
    [
      "=HYPERLINK(\"https://example.com\",\"x\")",
      " =HYPERLINK(\"https://example.com\",\"x\")",
      "\n=HYPERLINK(\"https://example.com\",\"x\")",
      "\t@SUM(1,1)",
      "\r-10"
    ].each do |value|
      assert_equal "'#{value}", Exporters::CellSanitizer.call(value)
    end
  end

  test "renders sanitized formulas in csv and xlsx exports" do
    malicious_language = " \n=HYPERLINK(\"https://example.com\",\"x\")"
    create_evaluation_target(language_name: malicious_language)

    csv_export = Exporters::ReportFactory.call(report_key: "evaluation_targets", format: "csv")
    csv_rows = CSV.parse(csv_export.body, headers: true)
    assert csv_rows.any? { |row| row["言語"] == "'#{malicious_language}" }

    xlsx_export = Exporters::ReportFactory.call(report_key: "evaluation_targets", format: "xlsx")
    Tempfile.create([ "evaluation-targets-export", ".xlsx" ]) do |file|
      file.binmode
      file.write(xlsx_export.body)
      file.flush

      workbook = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      languages = 2.upto(workbook.sheet(0).last_row).map { |row_number| workbook.sheet(0).cell(row_number, 3) }
      assert_includes languages, "'#{malicious_language}"
    end
  end

  test "exports evaluation targets as xlsx" do
    language_name = "Ruby #{SecureRandom.hex(4)}"
    create_evaluation_target(language_name: language_name)

    export = Exporters::ReportFactory.call(report_key: "evaluation_targets", format: "xlsx")

    Tempfile.create([ "evaluation-targets-export", ".xlsx" ]) do |file|
      file.binmode
      file.write(export.body)
      file.flush

      workbook = Roo::Spreadsheet.open(file.path, extension: :xlsx)
      assert_equal "受験対象マスタ", workbook.sheets.first
      assert_equal "言語", workbook.sheet(0).cell(1, 3)
      assert_equal language_name, workbook.sheet(0).cell(workbook.sheet(0).last_row, 3)
    end
  end

  test "raises for unknown report and unknown format" do
    assert_raises(Exporters::ReportFactory::UnknownReportError) do
      Exporters::ReportFactory.call(report_key: "unknown", format: "csv")
    end

    assert_raises(Exporters::ReportFactory::UnknownFormatError) do
      Exporters::ReportFactory.call(report_key: "evaluation_targets", format: "pdf")
    end
  end

  private

  def create_evaluation_target(language_name:)
    token = SecureRandom.hex(4)
    language = ProgrammingLanguage.create!(name: language_name)
    framework = Framework.create!(name: "Rails #{token}", programming_language: language)
    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{token}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv#{rand(10_000..99_999)}", numeric_level: 2),
      external_knowledge_key: "rails_lv2_#{token}",
      version: "2026.06-#{token}"
    )
  end
end
