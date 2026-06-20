class ReviewApplicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      return scope.joins(:exam_application).where(exam_applications: { candidate_id: user.id }) if user.candidate?

      scope.none
    end
  end

  def show?
    owner? || user.admin?
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

  private

  def owner?
    user.candidate? && record.exam_application.candidate_id == user.id
  end

  def reviewable_exam_application?
    record.exam_application.declared? || record.exam_application.reviewing?
  end
end
