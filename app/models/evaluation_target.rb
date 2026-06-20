require "uri"

class EvaluationTarget < ApplicationRecord
  acts_as_paranoid

  belongs_to :skill_area
  belongs_to :programming_language
  belongs_to :framework, optional: true
  belongs_to :skill_level
  has_many :examiner_skill_capabilities, dependent: :restrict_with_error
  has_many :examiner_profiles, through: :examiner_skill_capabilities

  validates :version, presence: true, length: { maximum: 50 }
  validates :external_knowledge_url, length: { maximum: 500 }, allow_blank: true
  validates :external_knowledge_key, length: { maximum: 200 }, allow_blank: true
  validates :description, length: { maximum: 2_000 }, allow_blank: true
  validates :display_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :external_knowledge_reference_present
  validate :external_knowledge_url_is_http_url
  validate :framework_matches_programming_language
  validate :identity_is_unique_among_active_targets

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:display_order, :id) }

  def display_name
    [
      programming_language.name,
      framework&.name,
      skill_level.code,
      version
    ].compact.join(" ")
  end

  private

  def external_knowledge_reference_present
    return if external_knowledge_url.present? || external_knowledge_key.present?

    errors.add(:base, "external knowledge url or key is required")
  end

  def external_knowledge_url_is_http_url
    return if external_knowledge_url.blank?

    uri = URI.parse(external_knowledge_url)
    return if uri.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:external_knowledge_url, "must be an HTTP or HTTPS URL")
  rescue URI::InvalidURIError
    errors.add(:external_knowledge_url, "must be an HTTP or HTTPS URL")
  end

  def framework_matches_programming_language
    return if framework.blank? || programming_language.blank?
    return if framework.programming_language_id.blank? || framework.programming_language_id == programming_language_id

    errors.add(:framework, "must belong to the selected programming language")
  end

  def identity_is_unique_among_active_targets
    return if programming_language_id.blank? || skill_level_id.blank? || version.blank?

    duplicate = self.class.unscoped.where(
      programming_language_id: programming_language_id,
      framework_id: framework_id,
      skill_level_id: skill_level_id,
      version: version,
      deleted_at: nil
    )
    duplicate = duplicate.where.not(id: id) if persisted?

    errors.add(:base, "evaluation target identity has already been taken") if duplicate.exists?
  end
end
