class AuditLog < ApplicationRecord
  acts_as_paranoid

  serialize :before_changes, coder: JSON
  serialize :after_changes, coder: JSON

  belongs_to :actor, class_name: "User", optional: true
  belongs_to :auditable, polymorphic: true, optional: true

  validates :action, presence: true, length: { maximum: 120 }
  validates :auditable_type, length: { maximum: 120 }
  validates :ip_address, length: { maximum: 255 }
  validates :user_agent, length: { maximum: 1000 }

  scope :recent, -> { order(created_at: :desc, id: :desc) }
end
