module Exporters
  class ReportFactory
    UnknownReportError = Class.new(StandardError)
    UnknownFormatError = Class.new(StandardError)

    REPORTS = {
      EvaluationTargetsReport::KEY => EvaluationTargetsReport,
      ReviewResultsReport::KEY => ReviewResultsReport,
      SubmissionStatusesReport::KEY => SubmissionStatusesReport,
      UserQualificationsReport::KEY => UserQualificationsReport
    }.freeze

    RENDERERS = {
      "csv" => CsvRenderer,
      "xlsx" => XlsxRenderer
    }.freeze

    Export = Struct.new(:report, :format, :filename, :content_type, :body, keyword_init: true)

    def self.reports
      REPORTS.values.map(&:new)
    end

    def self.call(report_key:, format:)
      report = build_report(report_key)
      renderer = renderer_for(format)

      Export.new(
        report: report,
        format: format,
        filename: report.filename(format),
        content_type: renderer::CONTENT_TYPE,
        body: renderer.call(report)
      )
    end

    def self.build_report(report_key)
      REPORTS.fetch(report_key).new
    rescue KeyError
      raise UnknownReportError, "unknown report: #{report_key}"
    end
    private_class_method :build_report

    def self.renderer_for(format)
      RENDERERS.fetch(format)
    rescue KeyError
      raise UnknownFormatError, "unknown export format: #{format}"
    end
    private_class_method :renderer_for
  end
end
