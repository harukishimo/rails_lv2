class ReviewApplication < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  IN_PROGRESS_STATUSES = %w[draft submitted returned].freeze

  prevents_restore_duplicates_by :exam_application_id, :sequence_number

  enum :status, {
    draft: 0,
    submitted: 1,
    returned: 2,
    approved: 3,
    rejected: 4,
    canceled: 5
  }, default: :draft, validate: true

  belongs_to :exam_application
  belongs_to :decided_by, class_name: "User", optional: true
  has_many :submissions, dependent: :restrict_with_error
  has_many :review_comments, dependent: :restrict_with_error
  has_many :review_decisions, dependent: :restrict_with_error
  has_many :status_change_events, as: :subject
  has_many :audit_logs, as: :auditable

  accepts_nested_attributes_for :submissions

  validates :sequence_number, numericality: { only_integer: true, greater_than: 0 }
  validates :appeal_markdown, length: { maximum: 10_000 }
  validates :submitted_at, presence: true, if: :submitted?
  validates :canceled_at, presence: true, if: :canceled?
  validates :decided_at, presence: true, if: :decision_status?
  validate :exam_application_accepts_review, on: :create
  validate :sequence_number_is_unique_among_active_records
  validate :in_progress_review_is_unique
  validate :evidence_submission_is_present, if: :submitted?

  before_validation :render_appeal_markdown
  before_restore :prevent_restore_in_progress_duplicate

  scope :in_progress, -> { where(status: statuses.values_at(*IN_PROGRESS_STATUSES)) }
  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def editable?
    return false if exam_application.blank? || exam_application.closed_for_business?

    draft? || submitted? || returned?
  end

  def cancelable?
    editable?
  end

  def commentable?
    !closed_for_review? && !exam_application.closed_for_business?
  end

  def decidable?
    submitted? && !exam_application.closed_for_business?
  end

  def closed_for_review?
    canceled? || approved? || rejected?
  end

  def display_name
    "レビュー ##{sequence_number} / #{exam_application.display_name}"
  end

  private

  def render_appeal_markdown
    self.rendered_appeal_html = MarkdownRenderer.call(appeal_markdown)
  end

  def decision_status?
    approved? || rejected?
  end

  def exam_application_accepts_review
    return if exam_application&.declared? || exam_application&.reviewing?

    errors.add(:exam_application, :must_be_declared_or_reviewing)
  end

  def sequence_number_is_unique_among_active_records
    return if exam_application_id.blank? || sequence_number.blank?

    duplicate = self.class.unscoped.where(
      exam_application_id: exam_application_id,
      sequence_number: sequence_number,
      deleted_at: nil
    )
    duplicate = duplicate.where.not(id: id) if persisted?

    errors.add(:sequence_number, :taken) if duplicate.exists?
  end

  def in_progress_review_is_unique
    return unless in_progress_status?
    return if exam_application_id.blank?

    duplicate = self.class.unscoped.where(
      exam_application_id: exam_application_id,
      status: self.class.statuses.values_at(*IN_PROGRESS_STATUSES),
      deleted_at: nil
    )
    duplicate = duplicate.where.not(id: id) if persisted?

    errors.add(:base, :in_progress_review_application_exists) if duplicate.exists?
  end

  def evidence_submission_is_present
    return if submissions.reject(&:marked_for_destruction?).any?(&:evidence?)

    errors.add(:base, :review_evidence_required)
  end

  def prevent_restore_in_progress_duplicate
    return unless in_progress_status?
    return if exam_application_id.blank?

    duplicate = self.class.unscoped.where(
      exam_application_id: exam_application_id,
      status: self.class.statuses.values_at(*IN_PROGRESS_STATUSES),
      deleted_at: nil
    )
    duplicate = duplicate.where.not(id: id) if id.present?
    return unless duplicate.exists?

    errors.add(:base, :cannot_restore_in_progress_review_application_exists)
    throw(:abort)
  end

  def in_progress_status?
    IN_PROGRESS_STATUSES.include?(status)
  end
end
