module Admin
  class ExaminerProfilePolicy < ApplicationPolicy
    class Scope < Scope
      def resolve
        admin? ? scope.all : scope.none
      end

      private

      def admin?
        user&.active_for_authentication? && user.admin?
      end
    end

    def index?
      admin?
    end

    def update?
      admin?
    end

    def edit?
      update?
    end
  end
end
