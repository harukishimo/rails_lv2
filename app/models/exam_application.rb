class ExamApplication < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :evaluation_period_id, :candidate_id, :evaluation_target_id, :attempt_number

  CLOSED_STATUSES = %w[closed].freeze

  enum :status, {
    draft: 0,
    declared: 1,
    reviewing: 2,
    review_approved: 3,
    interview_requested: 4,
    interview_scheduled: 5,
    passed: 6,
    failed: 7,
    canceled: 8,
    closed: 9
  }, default: :draft, validate: true

  enum :result, {
    none: 0,
    passed: 1,
    failed: 2,
    canceled: 3
  }, prefix: true, default: :none, validate: true

  belongs_to :evaluation_period
  belongs_to :candidate, class_name: "User"
  belongs_to :evaluation_target

  has_many :review_applications, dependent: :restrict_with_error
  has_one :interview_application
  has_one :user_qualification

  validates :attempt_number, numericality: { only_integer: true, greater_than: 0 }
  validates :declared_at, presence: true, unless: :draft?
  validates :closed_at, presence: true, if: :closed?
  validate :candidate_has_candidate_role
  validate :evaluation_target_is_active, on: :create
  validate :evaluation_period_is_active, on: :create
  validate :evaluation_period_includes_today, on: :create
  validate :attempt_number_is_unique_among_active_records
  validate :open_application_identity_is_unique

  before_restore :prevent_restore_open_duplicate

  scope :open, -> { where.not(status: statuses.fetch(:closed)) }
  scope :closed_status, -> { where(status: statuses.fetch(:closed)) }
  scope :for_candidate, ->(candidate) { where(candidate: candidate) }
  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def display_name
    "#{evaluation_target.display_name} / #{evaluation_period.name} / attempt #{attempt_number}"
  end

  def closed_for_business?
    closed?
  end

  private

  def candidate_has_candidate_role
    return if candidate&.candidate?

    errors.add(:candidate, "must have candidate role")
  end

  def evaluation_target_is_active
    return if evaluation_target&.active?

    errors.add(:evaluation_target, "must be active")
  end

  def evaluation_period_is_active
    return if evaluation_period&.active?

    errors.add(:evaluation_period, "must be active")
  end

  def evaluation_period_includes_today
    return if evaluation_period.blank?
    return if evaluation_period.cover?(Date.current)

    errors.add(:evaluation_period, "must include today")
  end

  def attempt_number_is_unique_among_active_records
    return if evaluation_period_id.blank? || candidate_id.blank? || evaluation_target_id.blank? || attempt_number.blank?

    duplicate = self.class.unscoped.where(
      evaluation_period_id: evaluation_period_id,
      candidate_id: candidate_id,
      evaluation_target_id: evaluation_target_id,
      attempt_number: attempt_number,
      deleted_at: nil
    )
    duplicate = duplicate.where.not(id: id) if persisted?

    errors.add(:attempt_number, "has already been taken") if duplicate.exists?
  end

  def open_application_identity_is_unique
    return if closed?
    return if evaluation_period_id.blank? || candidate_id.blank? || evaluation_target_id.blank?

    duplicate = self.class.unscoped.where(
      evaluation_period_id: evaluation_period_id,
      candidate_id: candidate_id,
      evaluation_target_id: evaluation_target_id,
      deleted_at: nil
    ).where.not(status: self.class.statuses.fetch(:closed))
    duplicate = duplicate.where.not(id: id) if persisted?

    errors.add(:base, "open exam application already exists for this candidate and target") if duplicate.exists?
  end

  def prevent_restore_open_duplicate
    return if closed?
    return if evaluation_period_id.blank? || candidate_id.blank? || evaluation_target_id.blank?

    duplicate = self.class.unscoped.where(
      evaluation_period_id: evaluation_period_id,
      candidate_id: candidate_id,
      evaluation_target_id: evaluation_target_id,
      deleted_at: nil
    ).where.not(status: self.class.statuses.fetch(:closed))
    duplicate = duplicate.where.not(id: id) if id.present?
    return unless duplicate.exists?

    errors.add(:base, "cannot restore because open exam application already exists")
    throw(:abort)
  end
end
