class SkillLevel < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :code, case_insensitive: :code

  has_many :evaluation_targets, dependent: :restrict_with_error

  validates :code, presence: true, length: { maximum: 30 },
                   uniqueness: { case_sensitive: false, conditions: -> { where(deleted_at: nil) } }
  validates :numeric_level, numericality: { only_integer: true, greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:numeric_level, :code) }
end
