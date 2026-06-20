require "csv"

module Exporters
  class CsvRenderer
    CONTENT_TYPE = "text/csv; charset=utf-8"

    def self.call(report)
      new(report).call
    end

    def initialize(report)
      @report = report
    end

    def call
      CSV.generate(headers: report.headers, write_headers: true) do |csv|
        report.each_row do |row|
          csv << row.map { |value| CellSanitizer.call(value) }
        end
      end
    end

    private

    attr_reader :report
  end
end
