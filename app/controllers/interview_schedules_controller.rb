class InterviewSchedulesController < ApplicationController
  before_action :authenticate_user!

  def create
    interview_application = policy_scope(InterviewApplication).find(params[:interview_application_id])
    interview_schedule = interview_application.interview_schedules.build
    authorize interview_schedule

    created_schedule = InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: current_user,
      attributes: interview_schedule_params.to_h.deep_symbolize_keys
    )

    redirect_to interview_application_path(created_schedule.interview_application), notice: "希望日時を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  def approve
    interview_schedule = policy_scope(InterviewSchedule).find(params[:id])
    authorize interview_schedule

    approved_schedule = InterviewSchedules::ApproveService.call(
      interview_schedule: interview_schedule,
      actor: current_user
    )

    redirect_to interview_application_path(approved_schedule.interview_application), notice: "面談日時を承認しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  def reject
    interview_schedule = policy_scope(InterviewSchedule).find(params[:id])
    authorize interview_schedule

    rejected_schedule = InterviewSchedules::RejectService.call(
      interview_schedule: interview_schedule,
      actor: current_user
    )

    redirect_to interview_application_path(rejected_schedule.interview_application), notice: "面談日時を差し戻しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  private

  def interview_schedule_params
    params.require(:interview_schedule).permit(:starts_at, :ends_at, :timezone)
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
