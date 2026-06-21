require "csv"

module Exporters
  class CsvRenderer
    CONTENT_TYPE = "text/csv; charset=utf-8"

    def self.call(report)
      new(report).call
    end

    def self.stream(report)
      new(report).stream
    end

    def initialize(report)
      @report = report
    end

    def call
      body = +""
      stream.each { |chunk| body << chunk }
      body
    end

    def stream
      Enumerator.new do |yielder|
        yielder << CSV.generate_line(report.headers)
        report.each_row do |row|
          yielder << CSV.generate_line(row.map { |value| CellSanitizer.call(value) })
        end
      end
    end

    private

    attr_reader :report
  end
end
