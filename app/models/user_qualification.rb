class UserQualification < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :user_id, :evaluation_target_id

  belongs_to :user
  belongs_to :evaluation_target
  belongs_to :exam_application
  belongs_to :granted_by, class_name: "User"

  validates :acquired_on, presence: true
  validate :exam_application_matches_user_and_target
  validate :active_user_target_is_unique

  scope :active, -> { where(revoked_at: nil) }
  scope :recent, -> { order(acquired_on: :desc, id: :desc) }

  private

  def exam_application_matches_user_and_target
    return if exam_application.blank?

    errors.add(:exam_application, "must belong to user") unless exam_application.candidate_id == user_id
    return if exam_application.evaluation_target_id == evaluation_target_id

    errors.add(:exam_application, "must match evaluation target")
  end

  def active_user_target_is_unique
    return if user_id.blank? || evaluation_target_id.blank? || revoked_at.present?

    duplicate = self.class.unscoped.where(
      user_id: user_id,
      evaluation_target_id: evaluation_target_id,
      revoked_at: nil,
      deleted_at: nil
    )
    duplicate = duplicate.where.not(id: id) if persisted?

    errors.add(:base, "active qualification already exists for this user and target") if duplicate.exists?
  end
end
