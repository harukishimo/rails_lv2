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

  def assignment
    interview_application = policy_scope(InterviewApplication).find(params[:id])
    authorize interview_application
    suggested_examiner = ExaminerSuggestionService.call(interview_application: interview_application)

    render plain: assignment_summary(interview_application, suggested_examiner)
  end

  def assign
    interview_application = policy_scope(InterviewApplication).find(params[:id])
    authorize interview_application
    assigned_application = InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: current_user,
      examiner_profile: ExaminerProfile.find(assignment_params.fetch(:assigned_examiner_profile_id)),
      reason: assignment_params[:assignment_override_reason]
    )

    redirect_to interview_application_path(assigned_application), notice: "面談評価官を確定しました"
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

  def assignment_summary(interview_application, suggested_examiner)
    [
      "Assignment for #{interview_application.display_name}",
      "current_examiner=#{interview_application.assigned_examiner_name}",
      "suggested_examiner_id=#{suggested_examiner&.id}",
      "suggested_examiner=#{suggested_examiner&.display_name || "候補なし"}"
    ].join("\n")
  end

  def assignment_params
    params.require(:interview_application).permit(:assigned_examiner_profile_id, :assignment_override_reason)
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
