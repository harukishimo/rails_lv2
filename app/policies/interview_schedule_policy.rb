class InterviewSchedulePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      interview_applications = Pundit.policy_scope!(user, InterviewApplication)
      scope.where(interview_application_id: interview_applications.select(:id))
    end
  end

  def create?
    interview_application_policy.schedule?
  end

  def approve?
    record.approvable? && interview_application_policy.approve_schedule?
  end

  def reject?
    record.rejectable? && interview_application_policy.reject_schedule?
  end

  private

  def interview_application_policy
    @interview_application_policy ||= InterviewApplicationPolicy.new(user, record.interview_application)
  end
end
