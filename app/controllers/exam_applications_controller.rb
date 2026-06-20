class ExamApplicationsController < ApplicationController
  before_action :authenticate_user!

  def index
    exam_applications = Search::ExamApplicationSearch.new(policy_scope(ExamApplication), search_params).relation

    render plain: exam_applications.map { |exam_application| exam_application_line(exam_application) }.join("\n")
  end

  def show
    exam_application = policy_scope(ExamApplication).find(params[:id])
    authorize exam_application

    render plain: exam_application.display_name
  end

  def new
    exam_application = ExamApplication.new(candidate: current_user)
    authorize exam_application

    render plain: "New exam application"
  end

  def create
    exam_application = build_authorization_record
    authorize exam_application

    created_application = ExamApplications::CreateService.call(
      candidate: current_user,
      evaluation_period: exam_application.evaluation_period,
      evaluation_target: exam_application.evaluation_target,
      actor: current_user
    )

    redirect_to exam_application_path(created_application), notice: "受験表明を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    render plain: error.record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end

  private

  def search_params
    params.permit(:status, :result, :evaluation_target_id, :candidate_id, :keyword, :page, :per_page)
  end

  def exam_application_line(exam_application)
    [
      "exam_application=#{exam_application.id}",
      exam_application.display_name,
      "status=#{exam_application.status}",
      "result=#{exam_application.result}",
      "candidate=#{exam_application.candidate.name}<#{exam_application.candidate.email}>",
      "target=#{exam_application.evaluation_target.display_name}",
      "period=#{exam_application.evaluation_period.name}"
    ].join(" | ")
  end

  def build_authorization_record
    ExamApplication.new(
      candidate: current_user,
      evaluation_period: EvaluationPeriod.find(exam_application_params.fetch(:evaluation_period_id)),
      evaluation_target: EvaluationTarget.find(exam_application_params.fetch(:evaluation_target_id))
    )
  end

  def exam_application_params
    params.require(:exam_application).permit(:evaluation_period_id, :evaluation_target_id)
  end
end
