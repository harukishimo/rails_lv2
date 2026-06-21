class EvaluationPeriod < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :name, case_insensitive: :name

  has_many :exam_applications, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { case_sensitive: false, conditions: -> { where(deleted_at: nil) } }
  validates :starts_on, :ends_on, presence: true
  validate :date_range_is_valid

  scope :active, -> { where(active: true) }
  scope :current, ->(date = Date.current) { active.where("starts_on <= ? AND ends_on >= ?", date, date) }
  scope :ordered, -> { order(starts_on: :desc, ends_on: :desc, id: :desc) }

  def cover?(date)
    return false if starts_on.blank? || ends_on.blank?

    date_range.cover?(date)
  end

  private

  def date_range
    starts_on..ends_on
  end

  def date_range_is_valid
    return if starts_on.blank? || ends_on.blank?
    return if starts_on <= ends_on

    errors.add(:ends_on, :on_or_after_starts_on)
  end
end
