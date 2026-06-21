class InterviewSchedule < ApplicationRecord
  acts_as_paranoid

  DEFAULT_TIMEZONE = "Asia/Tokyo".freeze

  enum :status, {
    requested: 0,
    approved: 1,
    rejected: 2,
    calendar_created: 3
  }, default: :requested, validate: true

  belongs_to :interview_application

  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :timezone, presence: true
  validate :timezone_must_be_known
  validate :starts_at_must_be_before_ends_at
  validate :starts_at_must_be_future

  before_validation :assign_default_timezone

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def display_name
    "#{starts_at&.in_time_zone(timezone)&.to_fs(:db)} - #{ends_at&.in_time_zone(timezone)&.to_fs(:db)}"
  end

  def approvable?
    requested? && interview_application.schedulable?
  end

  def rejectable?
    approvable?
  end

  private

  def assign_default_timezone
    self.timezone = DEFAULT_TIMEZONE if timezone.blank?
  end

  def starts_at_must_be_before_ends_at
    return if starts_at.blank? || ends_at.blank?
    return if starts_at < ends_at

    errors.add(:starts_at, "must be before ends_at")
  end

  def starts_at_must_be_future
    return if starts_at.blank?
    return if starts_at > Time.current

    errors.add(:starts_at, "must be in the future")
  end

  def timezone_must_be_known
    return if timezone.blank?
    return if Time.find_zone(timezone).present?

    errors.add(:timezone, "is invalid")
  end
end
