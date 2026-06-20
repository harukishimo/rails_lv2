class StatusChangeEvent < ApplicationRecord
  acts_as_paranoid

  serialize :metadata, coder: JSON

  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true

  validates :subject, presence: true
  validates :to_status, presence: true
  validates :event_type, presence: true
end
