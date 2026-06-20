module Admin
  class DashboardController < ApplicationController
    before_action :authenticate_user!

    def show
      authorize :admin_dashboard, :show?
    end
  end
end
