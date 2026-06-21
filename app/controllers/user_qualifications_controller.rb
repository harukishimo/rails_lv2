class UserQualificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @qualifications = Search::UserQualificationSearch.new(policy_scope(UserQualification), search_params).relation
  end

  private

  def search_params
    params.permit(
      :user_keyword,
      :evaluation_target_id,
      :acquired_on_from,
      :acquired_on_to,
      :page,
      :per_page
    )
  end
end
