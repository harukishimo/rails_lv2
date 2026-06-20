class SkillArea < ApplicationRecord
  acts_as_paranoid

  has_many :evaluation_targets, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 100 },
                   uniqueness: { case_sensitive: false, conditions: -> { where(deleted_at: nil) } }
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:display_order, :name) }
end
