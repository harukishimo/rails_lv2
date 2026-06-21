class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    authorize :dashboard, :show?

    @exam_applications = policy_scope(ExamApplication)
                         .includes(evaluation_target: %i[programming_language framework skill_level])
                         .recent
                         .limit(5)
    @qualifications = policy_scope(UserQualification)
                      .includes(evaluation_target: %i[programming_language framework skill_level])
                      .recent
                      .limit(5)
    @review_queue = review_queue
    @interview_queue = interview_queue
  end

  private

  def review_queue
    return ReviewApplication.none unless policy(ReviewApplication).queue?

    ReviewApplicationPolicy::QueueScope.new(current_user, ReviewApplication.all).resolve
      .includes(exam_application: [
        :candidate,
        { evaluation_target: %i[programming_language framework skill_level] }
      ])
      .submitted
      .recent
      .limit(5)
  end

  def interview_queue
    return InterviewApplication.none unless policy(InterviewApplication).queue?

    InterviewApplicationPolicy::QueueScope.new(current_user, InterviewApplication.all).resolve
      .includes(
        :assigned_examiner_profile,
        :secondary_assigned_examiner_profile,
        exam_application: [
          :candidate,
          { evaluation_target: %i[skill_area programming_language framework skill_level] }
        ]
      )
      .where.not(status: InterviewApplication.statuses.fetch(:completed))
      .recent
      .limit(5)
  end
end
