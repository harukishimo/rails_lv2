class InterviewApplicationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @interview_application = policy_scope(InterviewApplication)
                             .includes(
                               :interview_schedules,
                               :interview_result,
                               :assigned_examiner_profile,
                               :secondary_assigned_examiner_profile,
                               exam_application: [
                                 :candidate,
                                 { evaluation_target: %i[skill_area programming_language framework skill_level] }
                               ]
                             )
                             .find(params[:id])
    authorize @interview_application
    @interview_schedule = @interview_application.interview_schedules.build
    @persisted_interview_result = @interview_application.interview_result
    @interview_result = @persisted_interview_result || InterviewResult.new(interview_application: @interview_application)
  end

  def new
    @exam_application = policy_scope(ExamApplication).find(params[:exam_application_id])
    return redirect_unpermitted_interview_application if interview_application_not_yet_permitted_for_owner?

    @interview_application = InterviewApplication.new(exam_application: @exam_application)
    authorize @interview_application
  end

  def create
    @exam_application = policy_scope(ExamApplication).find(params[:exam_application_id])
    return redirect_unpermitted_interview_application if interview_application_not_yet_permitted_for_owner?

    @interview_application = InterviewApplication.new(exam_application: @exam_application)
    authorize @interview_application

    created_application = InterviewApplications::CreateService.call(
      exam_application: @exam_application,
      actor: current_user
    )

    redirect_to interview_application_path(created_application), notice: "面談応募を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    @interview_application = error.record
    @exam_application = @interview_application.exam_application
    flash.now[:alert] = "面談応募を登録できませんでした"
    render :new, status: :unprocessable_entity
  end

  def assignment
    @interview_application = policy_scope(InterviewApplication).find(params[:id])
    authorize @interview_application
    prepare_assignment_options
  end

  def assign
    @interview_application = policy_scope(InterviewApplication).find(params[:id])
    authorize @interview_application
    assigned_application = InterviewApplications::AssignExaminerService.call(
      interview_application: @interview_application,
      actor: current_user,
      examiner_profile: selected_examiner_profile,
      secondary_examiner_profile: selected_secondary_examiner_profile,
      reason: assignment_params[:assignment_override_reason]
    )

    redirect_to interview_application_path(assigned_application), notice: "面談評価官を確定しました"
  rescue ActiveRecord::RecordInvalid => error
    @interview_application = error.record
    prepare_assignment_options
    flash.now[:alert] = "面談評価官を確定できませんでした"
    render :assignment, status: :unprocessable_entity
  end

  private

  def interview_application_not_yet_permitted_for_owner?
    current_user.candidate? &&
      @exam_application.candidate_id == current_user.id &&
      !InterviewApplication.exists?(exam_application_id: @exam_application.id) &&
      !@exam_application.interview_permitted?
  end

  def redirect_unpermitted_interview_application
    authorize @exam_application, :show?
    redirect_to exam_application_path(@exam_application), alert: "面談応募は評価官が許可すると作成できます"
  end

  def prepare_assignment_options
    @suggested_examiners = ExaminerSuggestionService.call(interview_application: @interview_application, limit: 2)
    @examiner_profiles = ExaminerProfile.available_for_interviews
                                       .joins(:examiner_skill_capabilities)
                                       .where(examiner_skill_capabilities: {
                                         evaluation_target_id: @interview_application.exam_application.evaluation_target_id,
                                         active: true,
                                         can_interview: true
                                       })
                                       .distinct
                                       .order(:display_name, :id)
    @selected_primary_examiner_id = @interview_application.assigned_examiner_profile_id || @suggested_examiners.first&.id
    @selected_secondary_examiner_id = @interview_application.secondary_assigned_examiner_profile_id || @suggested_examiners.second&.id
  end

  def selected_examiner_profile
    ExaminerProfile.find_by(id: assignment_params[:assigned_examiner_profile_id])
  end

  def selected_secondary_examiner_profile
    ExaminerProfile.find_by(id: assignment_params[:secondary_assigned_examiner_profile_id])
  end

  def assignment_params
    params.require(:interview_application).permit(
      :assigned_examiner_profile_id,
      :secondary_assigned_examiner_profile_id,
      :assignment_override_reason
    )
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
