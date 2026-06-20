class UserQualificationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      return scope.where(user: user) if user.candidate?
      return scope.where(evaluation_target_id: evaluation_target_ids) if user.examiner?

      scope.none
    end

    private

    def evaluation_target_ids
      profile = user.examiner_profile
      return [] unless profile&.active?

      capabilities = profile.examiner_skill_capabilities.active
      visible = ExaminerSkillCapability.none
      visible = visible.or(capabilities.where(can_review: true)) if profile.can_review?
      visible = visible.or(capabilities.where(can_interview: true)) if profile.can_interview?
      visible.pluck(:evaluation_target_id)
    end
  end
end
