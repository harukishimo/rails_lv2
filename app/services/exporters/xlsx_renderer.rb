require "caxlsx"

module Exporters
  class XlsxRenderer
    CONTENT_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

    def self.call(report)
      new(report).call
    end

    def initialize(report)
      @report = report
    end

    def call
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: report.title) do |sheet|
        sheet.add_row report.headers
        report.each_row do |row|
          sheet.add_row row.map { |value| CellSanitizer.call(value) }
        end
      end
      package.to_stream.read
    end

    private

    attr_reader :report
  end
end
