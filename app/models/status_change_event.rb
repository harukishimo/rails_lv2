class StatusChangeEvent < ApplicationRecord
  acts_as_paranoid

  serialize :metadata, coder: JSON

  belongs_to :actor, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true
  has_many :slack_deliveries, dependent: :restrict_with_error

  validates :subject, presence: true
  validates :to_status, presence: true
  validates :event_type, presence: true

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def localized_event_type
    localized_label(event_type)
  end

  def localized_transition
    return localized_label(to_status) if from_status.blank?

    "#{localized_label(from_status)} → #{localized_label(to_status)}"
  end

  def localized_message
    return "#{localized_subject_name}が#{localized_label(to_status)}になりました" if from_status.blank?

    "#{localized_subject_name}を#{localized_label(from_status)}から#{localized_label(to_status)}へ変更しました"
  end

  private

  def localized_subject_name
    subject_class = subject_type.safe_constantize
    return subject_type if subject_class.blank?

    subject_class.model_name.human(locale: :ja)
  end

  def localized_label(value)
    I18n.t("labels.#{value}", locale: :ja, default: value.to_s.humanize)
  end
end
