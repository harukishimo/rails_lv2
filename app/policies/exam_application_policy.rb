class ExamApplicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?
      return scope.where(candidate: user) if user.candidate?

      scope.none
    end
  end

  def index?
    user.present?
  end

  def show?
    user.admin? || record.candidate_id == user.id
  end

  def new?
    create?
  end

  def create?
    user.candidate? && (record.candidate_id.blank? || record.candidate_id == user.id)
  end
end
