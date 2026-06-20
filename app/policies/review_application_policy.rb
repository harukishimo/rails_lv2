class ReviewApplicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?

      visible_scope = scope.none
      visible_scope = visible_scope.or(scope.where(id: candidate_review_ids)) if user.candidate?
      visible_scope = visible_scope.or(scope.where(id: examiner_review_ids)) if user.examiner?
      visible_scope
    end

    private

    def candidate_review_ids
      scope.joins(:exam_application)
           .where(exam_applications: { candidate_id: user.id })
           .select(:id)
    end

    def examiner_review_ids
      scope.joins(:exam_application)
           .where(exam_applications: { evaluation_target_id: evaluation_target_ids })
           .select(:id)
    end

    def evaluation_target_ids
      user.examiner_profile&.examiner_skill_capabilities&.reviewable&.pluck(:evaluation_target_id) || []
    end
  end

  class QueueScope < Scope
    def resolve
      return scope.all if user.admin?
      return scope.none unless review_queue_visible?

      scope.joins(:exam_application)
           .where(exam_applications: { evaluation_target_id: evaluation_target_ids })
           .where.not(exam_applications: { candidate_id: user.id })
    end

    private

    def review_queue_visible?
      user.examiner? && user.examiner_profile&.active? && user.examiner_profile&.can_review?
    end

    def evaluation_target_ids
      user.examiner_profile&.examiner_skill_capabilities&.reviewable&.pluck(:evaluation_target_id) || []
    end
  end

  def show?
    owner? || user.admin? || examiner_capable?
  end

  def queue?
    user.admin? || (user.examiner? && user.examiner_profile&.active? && user.examiner_profile&.can_review?)
  end

  def create?
    user.candidate? && record.exam_application.candidate_id == user.id && reviewable_exam_application?
  end

  def new?
    create?
  end

  def update?
    (owner? || user.admin?) && record.editable?
  end

  def edit?
    update?
  end

  def cancel?
    (owner? || user.admin?) && record.cancelable?
  end

  def comment?
    (user.admin? || examiner_capable?) && record.commentable? && !self_review?
  end

  def decide?
    (user.admin? || examiner_capable?) && record.decidable? && !self_review?
  end

  private

  def owner?
    user.candidate? && record.exam_application.candidate_id == user.id
  end

  def self_review?
    record.exam_application.candidate_id == user.id
  end

  def examiner_capable?
    user.examiner? && user.examiner_profile&.can_evaluate?(record.exam_application.evaluation_target)
  end

  def reviewable_exam_application?
    record.exam_application.declared? || record.exam_application.reviewing?
  end
end
