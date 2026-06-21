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
end
