class AdminDashboardPolicy < ApplicationPolicy
  def show?
    admin?
  end
end
