require "fileutils"

module Admin
  class ExportsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    def show
      @reports = Exporters::ReportFactory.reports
    end

    def download
      export = Exporters::ReportFactory.download(report_key: params[:report], format: request.format.symbol.to_s)
      if export.file?
        send_file_export(export)
      else
        send_streaming_export(export)
      end
    rescue Exporters::ReportFactory::UnknownReportError, Exporters::ReportFactory::UnknownFormatError
      render plain: "Not Found", status: :not_found
    rescue Exporters::XlsxRenderer::TooManyRowsError
      render plain: "Export too large", status: :payload_too_large
    end

    private

    def authorize_admin!
      authorize :admin_dashboard, :show?
    end

    def send_streaming_export(export)
      response.headers["Content-Type"] = export.content_type
      response.headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format(
        disposition: "attachment",
        filename: export.filename
      )
      self.response_body = export.body
    end

    def send_file_export(export)
      response.headers["Content-Type"] = export.content_type
      response.headers["Content-Disposition"] = ActionDispatch::Http::ContentDisposition.format(
        disposition: "attachment",
        filename: export.filename
      )
      self.response_body = file_stream(export.path)
    end

    def file_stream(path)
      Enumerator.new do |yielder|
        File.open(path, "rb") do |file|
          while (chunk = file.read(16.kilobytes))
            yielder << chunk
          end
        end
      ensure
        FileUtils.rm_f(path)
      end
    end
  end
end
