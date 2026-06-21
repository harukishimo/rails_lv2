class InterviewResultsController < ApplicationController
  before_action :authenticate_user!

  def create
    interview_application = policy_scope(InterviewApplication).find(params[:interview_application_id])
    authorize interview_application, :decide_result?

    interview_result = QualificationGrantService.call(
      interview_application: interview_application,
      examiner: current_user,
      attributes: interview_result_params.to_h.deep_symbolize_keys
    )

    redirect_to interview_application_path(interview_result.interview_application), notice: "面談結果を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  rescue QualificationGrantService::QualificationGrantError => error
    render plain: error.message, status: :unprocessable_entity
  end

  private

  def interview_result_params
    params.require(:interview_result).permit(:result, :comment_markdown)
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
