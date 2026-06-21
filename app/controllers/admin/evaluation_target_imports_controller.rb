module Admin
  class EvaluationTargetImportsController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_admin!

    def new
      @result = nil
    end

    def preview
      @result = EvaluationTargets::Importer.preview(file: uploaded_file)
      render :new
    rescue ActionController::ParameterMissing
      render_missing_file
    rescue EvaluationTargets::Importer::UnsupportedFileError => e
      render_import_error(e.message)
    end

    def create
      @result = EvaluationTargets::Importer.import(file: uploaded_file)
      status = @result.success? ? :ok : :unprocessable_entity
      render :new, status: status
    rescue ActionController::ParameterMissing
      render_missing_file
    rescue EvaluationTargets::Importer::UnsupportedFileError => e
      render_import_error(e.message)
    end

    private

    def authorize_admin!
      authorize :admin_dashboard, :show?
    end

    def uploaded_file
      params.require(:file)
    end

    def render_missing_file
      render_import_error("ファイルを選択してください")
    end

    def render_import_error(message)
      @import_error = message
      @result = nil
      render :new, status: :unprocessable_entity
    end
  end
end
