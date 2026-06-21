require "caxlsx"
require "fileutils"
require "securerandom"

module Exporters
  class XlsxRenderer
    CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    MAX_EXPORT_ROWS = 10_000
    TooManyRowsError = Class.new(StandardError)

    def self.call(report)
      new(report).call
    end

    def self.write_file(report)
      new(report).write_file
    end

    def initialize(report)
      @report = report
    end

    def call
      path = write_file
      File.binread(path)
    ensure
      FileUtils.rm_f(path) if path.present?
    end

    def write_file
      path = export_path
      FileUtils.mkdir_p(File.dirname(path))
      write_to_path(path)
      path
    end

    private

    attr_reader :report

    def write_to_path(path)
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: report.title) do |sheet|
        sheet.add_row report.headers
        row_count = 0
        report.each_row do |row|
          row_count += 1
          raise TooManyRowsError, "XLSX export row limit exceeded" if row_count > MAX_EXPORT_ROWS

          sheet.add_row row.map { |value| CellSanitizer.call(value) }
        end
      end
      package.serialize(path)
    end

    def export_path
      Rails.root.join("tmp", "exports", "#{SecureRandom.hex(12)}-#{report.filename('xlsx')}").to_s
    end
  end
end
