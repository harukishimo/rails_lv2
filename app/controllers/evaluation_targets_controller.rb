class EvaluationTargetsController < ApplicationController
  before_action :authenticate_user!

  def index
    targets = Search::EvaluationTargetSearch.new(policy_scope(EvaluationTarget), search_params).relation

    render plain: targets.map { |target| evaluation_target_line(target) }.join("\n")
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

  def evaluation_target_line(target)
    [
      "target=#{target.id}",
      target.display_name,
      "active=#{target.active?}",
      "external_key=#{target.external_knowledge_key}"
    ].join(" | ")
  end
end
