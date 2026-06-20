class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      candidates = scope.joins(:roles).where(roles: { code: Role::CANDIDATE }).distinct
      return candidates if user.admin?
      return candidates.where(id: visible_candidate_ids) if user.examiner?

      candidates.where(id: user.id)
    end

    private

    def visible_candidate_ids
      ExamApplication.where(evaluation_target_id: evaluation_target_ids).select(:candidate_id)
    end

    def evaluation_target_ids
      visible_capability_scope.pluck(:evaluation_target_id)
    end

    def visible_capability_scope
      profile = user.examiner_profile
      return ExaminerSkillCapability.none unless profile&.active?

      capabilities = profile.examiner_skill_capabilities.active
      visible = ExaminerSkillCapability.none
      visible = visible.or(capabilities.where(can_review: true)) if profile.can_review?
      visible = visible.or(capabilities.where(can_interview: true)) if profile.can_interview?
      visible
    end
  end

  def candidate_index?
    user.admin? || user.examiner?
  end

  def candidate_show?
    return true if user.admin?
    return false unless user.examiner?

    record.exam_applications.where(evaluation_target_id: evaluation_target_ids).exists?
  end

  private

  def evaluation_target_ids
    visible_capability_scope.pluck(:evaluation_target_id)
  end

  def visible_capability_scope
    profile = user.examiner_profile
    return ExaminerSkillCapability.none unless profile&.active?

    capabilities = profile.examiner_skill_capabilities.active
    visible = ExaminerSkillCapability.none
    visible = visible.or(capabilities.where(can_review: true)) if profile.can_review?
    visible = visible.or(capabilities.where(can_interview: true)) if profile.can_interview?
    visible
  end
end
