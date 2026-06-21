class ReviewComment < ApplicationRecord
  acts_as_paranoid

  belongs_to :review_application
  belongs_to :examiner, class_name: "User"

  validates :body_markdown, presence: true, length: { maximum: 5_000 }
  validate :examiner_has_examiner_role
  validate :review_application_accepts_comments

  before_validation :render_body_markdown

  private

  def render_body_markdown
    self.rendered_body_html = MarkdownRenderer.call(body_markdown)
  end

  def examiner_has_examiner_role
    return if examiner&.examiner? || examiner&.admin?

    errors.add(:examiner, :examiner_role_required)
  end

  def review_application_accepts_comments
    return if review_application&.commentable?

    errors.add(:review_application, :must_accept_comments)
  end
end
