class UserQualificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    qualifications = Search::UserQualificationSearch.new(policy_scope(UserQualification), search_params).relation

    render plain: qualifications.map { |qualification| qualification_line(qualification) }.join("\n")
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

  def qualification_line(qualification)
    [
      "qualification=#{qualification.id}",
      "user=#{qualification.user.name}<#{qualification.user.email}>",
      "target=#{qualification.evaluation_target.display_name}",
      "acquired_on=#{qualification.acquired_on}",
      "granted_by=#{qualification.granted_by.name}"
    ].join(" | ")
  end
end
