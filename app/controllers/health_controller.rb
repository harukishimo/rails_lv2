class HealthController < ApplicationController
  skip_after_action :verify_pundit_authorization

  def index
  end
end
