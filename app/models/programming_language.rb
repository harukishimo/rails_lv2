class ProgrammingLanguage < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :name, case_insensitive: :name

  has_many :frameworks, dependent: :restrict_with_error
  has_many :evaluation_targets, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { case_sensitive: false, conditions: -> { where(deleted_at: nil) } }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
