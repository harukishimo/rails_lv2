class StatusChangeEventPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?

      visible_scope_for("ExamApplication", Pundit.policy_scope!(user, ExamApplication))
        .or(visible_scope_for("ReviewApplication", Pundit.policy_scope!(user, ReviewApplication)))
        .or(visible_scope_for("InterviewApplication", Pundit.policy_scope!(user, InterviewApplication)))
    end

    private

    def visible_scope_for(subject_type, relation)
      scope.where(subject_type: subject_type, subject_id: relation.select(:id))
    end
  end
end
