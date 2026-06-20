class ReviewDecisionsController < ApplicationController
  before_action :authenticate_user!

  def create
    review_application = policy_scope(ReviewApplication).find(params[:review_application_id])
    review_decision = review_application.review_decisions.build(examiner: current_user)
    authorize review_decision

    created_decision = ReviewDecisions::CreateService.call(
      review_application: review_application,
      examiner: current_user,
      attributes: review_decision_params.to_h.deep_symbolize_keys
    )

    redirect_to review_application_path(created_decision.review_application), notice: "レビュー判定を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  private

  def review_decision_params
    params.require(:review_decision).permit(:decision, :reason_markdown)
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
