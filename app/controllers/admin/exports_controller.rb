module Admin
  class ExportsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    def show
      @reports = Exporters::ReportFactory.reports
    end

    def download
      export = Exporters::ReportFactory.call(report_key: params[:report], format: request.format.symbol.to_s)
      send_data export.body, filename: export.filename, type: export.content_type, disposition: "attachment"
    rescue Exporters::ReportFactory::UnknownReportError, Exporters::ReportFactory::UnknownFormatError
      render plain: "Not Found", status: :not_found
    end

    private

    def authorize_admin!
      authorize :admin_dashboard, :show?
    end
  end
end
