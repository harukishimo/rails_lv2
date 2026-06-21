class DashboardPolicy < ApplicationPolicy
  def show?
    active_user?
  end
end
