class EvaluationTargetsController < ApplicationController
  before_action :authenticate_user!

  def index
    @evaluation_targets = Search::EvaluationTargetSearch.new(policy_scope(EvaluationTarget), search_params).relation
  end

  private

  def search_params
    params.permit(
      :skill_area_id,
      :programming_language_id,
      :framework_id,
      :skill_level_id,
      :active,
      :keyword,
      :page,
      :per_page
    )
  end
end
