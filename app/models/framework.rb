class Framework < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :programming_language_id, :name, case_insensitive: :name

  belongs_to :programming_language, optional: true
  has_many :evaluation_targets, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: {
                     scope: :programming_language_id,
                     case_sensitive: false,
                     conditions: -> { where(deleted_at: nil) }
                   }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
