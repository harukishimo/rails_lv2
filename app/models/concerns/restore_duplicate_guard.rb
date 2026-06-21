# frozen_string_literal: true

module RestoreDuplicateGuard
  extend ActiveSupport::Concern

  included do
    class_attribute :restore_duplicate_guard_attributes, default: []
    class_attribute :restore_duplicate_guard_case_insensitive_attributes, default: []

    before_restore :prevent_restore_duplicate
  end

  class_methods do
    def prevents_restore_duplicates_by(*attributes, case_insensitive: [])
      self.restore_duplicate_guard_attributes = attributes.map(&:to_sym)
      self.restore_duplicate_guard_case_insensitive_attributes = Array(case_insensitive).map(&:to_sym)
    end
  end

  private

  def prevent_restore_duplicate
    return if restore_duplicate_guard_attributes.blank?

    duplicate = self.class.unscoped.where(deleted_at: nil)
    restore_duplicate_guard_attributes.each do |attribute|
      duplicate = apply_restore_duplicate_condition(duplicate, attribute)
    end
    duplicate = duplicate.where.not(id: id) if id.present?

    return unless duplicate.exists?

    errors.add(:base, :active_duplicate_exists)
    throw(:abort)
  end

  def apply_restore_duplicate_condition(relation, attribute)
    value = public_send(attribute)
    return relation.where(attribute => value) unless restore_duplicate_guard_case_insensitive_attributes.include?(attribute) && value.present?

    column_name = self.class.connection.quote_column_name(attribute)
    relation.where("LOWER(#{column_name}) = ?", value.to_s.downcase)
  end
end
