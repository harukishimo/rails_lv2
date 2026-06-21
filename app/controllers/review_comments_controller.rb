class ReviewCommentsController < ApplicationController
  before_action :authenticate_user!

  def create
    review_application = policy_scope(ReviewApplication).find(params[:review_application_id])
    review_comment = review_application.review_comments.build(examiner: current_user)
    authorize review_comment

    created_comment = ReviewComments::CreateService.call(
      review_application: review_application,
      examiner: current_user,
      attributes: review_comment_params.to_h.deep_symbolize_keys
    )

    redirect_to review_application_path(created_comment.review_application), notice: "レビューコメントを登録しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  def update
    review_comment = policy_scope(ReviewComment).find(params[:id])
    authorize review_comment

    updated_comment = ReviewComments::UpdateService.call(
      review_comment: review_comment,
      examiner: current_user,
      attributes: review_comment_params.to_h.deep_symbolize_keys
    )

    redirect_to review_application_path(updated_comment.review_application), notice: "レビューコメントを更新しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  private

  def review_comment_params
    params.require(:review_comment).permit(:body_markdown)
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
