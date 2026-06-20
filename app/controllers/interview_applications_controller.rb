class InterviewApplicationsController < ApplicationController
  before_action :authenticate_user!

  def show
    interview_application = policy_scope(InterviewApplication).includes(:interview_schedules).find(params[:id])
    authorize interview_application

    render plain: interview_application_summary(interview_application)
  end

  def new
    exam_application = policy_scope(ExamApplication).find(params[:exam_application_id])
    interview_application = InterviewApplication.new(exam_application: exam_application)
    authorize interview_application

    render plain: "New interview application\n応募後は取消できません"
  end

  def create
    exam_application = policy_scope(ExamApplication).find(params[:exam_application_id])
    interview_application = InterviewApplication.new(exam_application: exam_application)
    authorize interview_application

    created_application = InterviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: current_user
    )

    redirect_to interview_application_path(created_application), notice: "面談応募を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  private

  def interview_application_summary(interview_application)
    [
      interview_application.display_name,
      "status=#{interview_application.status}",
      "assigned_examiner=#{interview_application.assigned_examiner_name}",
      interview_application.interview_schedules.map do |schedule|
        "schedule=#{schedule.display_name}:#{schedule.status}"
      end
    ].flatten.join("\n")
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
