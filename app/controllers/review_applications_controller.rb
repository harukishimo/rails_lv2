class ReviewApplicationsController < ApplicationController
  before_action :authenticate_user!

  def show
    @review_application = policy_scope(ReviewApplication)
                          .includes(
                            :submissions,
                            :review_comments,
                            :review_decisions,
                            exam_application: [
                              :candidate,
                              { evaluation_target: %i[skill_area programming_language framework skill_level] }
                            ]
                          )
                          .find(params[:id])
    authorize @review_application
    @review_comment = @review_application.review_comments.build
    @review_decision = @review_application.review_decisions.build
  end

  def new
    exam_application = policy_scope(ExamApplication).find(params[:exam_application_id])
    @review_application = exam_application.review_applications.build
    @review_application.submissions.build(kind: :github_repository, title: "Repository")
    authorize @review_application
  end

  def create
    exam_application = policy_scope(ExamApplication).find(params[:exam_application_id])
    @review_application = exam_application.review_applications.build
    authorize @review_application

    created_application = ReviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: current_user,
      attributes: review_application_params.to_h.deep_symbolize_keys
    )

    redirect_to review_application_path(created_application), notice: "レビュー依頼を登録しました"
  rescue ActiveRecord::RecordInvalid => error
    @review_application = error.record
    @review_application.submissions.build(kind: :github_repository, title: "Repository") if @review_application.submissions.empty?
    flash.now[:alert] = "レビュー依頼を登録できませんでした"
    render :new, status: :unprocessable_entity
  end

  def edit
    @review_application = policy_scope(ReviewApplication).includes(:submissions).find(params[:id])
    authorize @review_application
    @review_application.submissions.build(kind: :github_repository, title: "Repository") if @review_application.submissions.empty?
  end

  def update
    @review_application = policy_scope(ReviewApplication).find(params[:id])
    authorize @review_application

    updated_application = ReviewApplications::UpdateService.call(
      review_application: @review_application,
      actor: current_user,
      attributes: review_application_params.to_h.deep_symbolize_keys
    )

    redirect_to review_application_path(updated_application), notice: "レビュー依頼を更新しました"
  rescue ActiveRecord::RecordInvalid => error
    @review_application = error.record
    @review_application.submissions.build(kind: :github_repository, title: "Repository") if @review_application.submissions.empty?
    flash.now[:alert] = "レビュー依頼を更新できませんでした"
    render :edit, status: :unprocessable_entity
  end

  def cancel
    review_application = policy_scope(ReviewApplication).find(params[:id])
    authorize review_application, :cancel?

    canceled_application = ReviewApplications::CancelService.call(
      review_application: review_application,
      actor: current_user,
      cancel_reason: params.dig(:review_application, :cancel_reason)
    )

    redirect_to review_application_path(canceled_application), notice: "レビュー依頼を取り消しました"
  rescue ActiveRecord::RecordInvalid => error
    render_validation_errors(error.record)
  end

  private

  def review_application_params
    params.require(:review_application).permit(
      :appeal_markdown,
      submissions_attributes: %i[id kind title github_url note file]
    )
  end

  def render_validation_errors(record)
    render plain: record.errors.full_messages.to_sentence, status: :unprocessable_entity
  end
end
