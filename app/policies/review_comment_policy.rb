class ReviewCommentPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      return scope.where(examiner: user) if user.examiner?

      scope.none
    end
  end

  def create?
    review_application_policy.comment?
  end

  def update?
    (user.admin? || (record.examiner_id == user.id && examiner_capable?)) && !self_review?
  end

  private

  def review_application_policy
    ReviewApplicationPolicy.new(user, record.review_application)
  end

  def examiner_capable?
    user.examiner? && user.examiner_profile&.can_evaluate?(record.review_application.exam_application.evaluation_target)
  end

  def self_review?
    record.review_application.exam_application.candidate_id == user.id
  end
end
