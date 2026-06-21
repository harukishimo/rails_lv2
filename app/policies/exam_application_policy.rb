class ExamApplicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?

      visible_scope = scope.none
      visible_scope = visible_scope.or(scope.where(candidate: user)) if user.candidate?
      visible_scope = visible_scope.or(scope.where(evaluation_target_id: examiner_evaluation_target_ids)) if user.examiner?
      visible_scope
    end

    private

    def examiner_evaluation_target_ids
      profile = user.examiner_profile
      return [] unless profile&.active?

      capabilities = profile.examiner_skill_capabilities.active
      capabilities.where(can_review: true)
                  .or(capabilities.where(can_interview: true))
                  .pluck(:evaluation_target_id)
    end
  end

  def index?
    user.present?
  end

  def show?
    user.admin? || record.candidate_id == user.id || examiner_capable_for?(record.evaluation_target)
  end

  def new?
    create?
  end

  def create?
    user.candidate? && (record.candidate_id.blank? || record.candidate_id == user.id)
  end

  def permit_interview?
    (user.admin? || examiner_capable_for?(record.evaluation_target)) &&
      record.permit_interview? &&
      record.candidate_id != user.id
  end
end
