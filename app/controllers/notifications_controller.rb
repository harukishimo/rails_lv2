class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @status_change_events = policy_scope(StatusChangeEvent)
                            .includes(:actor)
                            .recent
                            .limit(100)
  end
end
