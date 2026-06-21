class ExamApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @exam_applications = Search::ExamApplicationSearch.new(policy_scope(ExamApplication), search_params).relation
  end

  def show
    @exam_application = policy_scope(ExamApplication)
                        .includes(
                          :review_applications,
                          :interview_application,
                          :user_qualification,
                          evaluation_target: %i[skill_area programming_language framework skill_level]
                        )
                        .find(params[:id])
    authorize @exam_application
  end

  def permit_interview
    @exam_application = policy_scope(ExamApplication).find(params[:id])
    authorize @exam_application

    ExamApplications::PermitInterviewService.call(
      exam_application: @exam_application,
      actor: current_user
    )

    redirect_to exam_application_path(@exam_application), notice: "面談応募を許可しました"
  rescue ActiveRecord::RecordInvalid => error
    redirect_to exam_application_path(error.record), alert: error.record.errors.full_messages.to_sentence
  end

  def new
    @exam_application = ExamApplication.new(candidate: current_user)
    authorize @exam_application
    prepare_form_options
  end

  def create
    @exam_application = build_authorization_record
    authorize @exam_application

    created_application = ExamApplications::CreateService.call(
      candidate: current_user,
      evaluation_period: @exam_application.evaluation_period,
      evaluation_target: @exam_application.evaluation_target,
      actor: current_user
    )

    redirect_to exam_application_path(created_application), notice: "受験表明を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    @exam_application = error.record
    prepare_form_options
    flash.now[:alert] = "受験表明を登録できませんでした"
    render :new, status: :unprocessable_entity
  end

  private

  def search_params
    params.permit(:status, :result, :evaluation_target_id, :candidate_id, :keyword, :page, :per_page, statuses: [])
  end

  def prepare_form_options
    @evaluation_periods = EvaluationPeriod.order(starts_on: :desc, id: :desc)
    @evaluation_targets = EvaluationTarget.active.includes(:programming_language, :framework, :skill_level).ordered
  end

  def build_authorization_record
    ExamApplication.new(
      candidate: current_user,
      evaluation_period: selected_evaluation_period,
      evaluation_target: selected_evaluation_target
    )
  end

  def exam_application_params
    params.require(:exam_application).permit(:evaluation_period_id, :evaluation_target_id)
  end

  def selected_evaluation_period
    EvaluationPeriod.find_by(id: exam_application_params[:evaluation_period_id])
  end

  def selected_evaluation_target
    EvaluationTarget.find_by(id: exam_application_params[:evaluation_target_id])
  end
end
