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

    Export = Struct.new(:report, :format, :filename, :content_type, :body, :path, keyword_init: true) do
      def file?
        path.present?
      end
    end

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

    def self.download(report_key:, format:)
      report = build_report(report_key)
      renderer = renderer_for(format)

      Export.new(
        report: report,
        format: format,
        filename: report.filename(format),
        content_type: renderer::CONTENT_TYPE,
        body: download_body(renderer, report),
        path: download_path(renderer, report)
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

    def self.download_body(renderer, report)
      renderer.stream(report) if renderer.respond_to?(:stream)
    end
    private_class_method :download_body

    def self.download_path(renderer, report)
      renderer.write_file(report) if renderer.respond_to?(:write_file)
    end
    private_class_method :download_path
  end
end
