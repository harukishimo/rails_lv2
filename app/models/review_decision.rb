class ReviewDecision < ApplicationRecord
  acts_as_paranoid

  enum :decision, {
    return_to_candidate: 0,
    approve: 1,
    reject: 2
  }, prefix: true, validate: true

  belongs_to :review_application
  belongs_to :examiner, class_name: "User"

  validates :decided_at, presence: true
  validates :reason_markdown, length: { maximum: 5_000 }
  validates :reason_markdown, presence: true, if: :reason_required?
  validate :examiner_has_examiner_role
  validate :review_application_accepts_decisions

  before_validation :set_default_decided_at
  before_validation :render_reason_markdown

  private

  def set_default_decided_at
    self.decided_at ||= Time.current
  end

  def render_reason_markdown
    self.rendered_reason_html = MarkdownRenderer.call(reason_markdown)
  end

  def reason_required?
    decision_return_to_candidate? || decision_reject?
  end

  def examiner_has_examiner_role
    return if examiner&.examiner? || examiner&.admin?

    errors.add(:examiner, "must be an examiner")
  end

  def review_application_accepts_decisions
    return if review_application&.decidable?

    errors.add(:review_application, "must accept decisions")
  end
end
