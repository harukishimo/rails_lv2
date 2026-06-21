class InterviewResult < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :interview_application_id

  enum :result, {
    passed: 0,
    failed: 1
  }, validate: true

  belongs_to :interview_application
  belongs_to :examiner, class_name: "User"

  validates :result, presence: true
  validates :decided_at, presence: true
  validates :comment_markdown, length: { maximum: 10_000 }
  validates :interview_application_id, uniqueness: { conditions: -> { where(deleted_at: nil) } }
  validate :examiner_can_decide_interview

  before_validation :render_comment_markdown

  private

  def render_comment_markdown
    self.rendered_comment_html = MarkdownRenderer.call(comment_markdown)
  end

  def examiner_can_decide_interview
    return if examiner&.admin?
    return if assigned_examiner?

    errors.add(:examiner, :must_be_assigned_examiner_or_admin)
  end

  def assigned_examiner?
    interview_application&.assigned_examiner_profiles&.any? { |profile| profile.user_id == examiner_id }
  end
end
