class ExaminerSkillCapability < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :examiner_profile_id, :evaluation_target_id

  belongs_to :examiner_profile
  belongs_to :evaluation_target

  validates :evaluation_target_id, presence: true,
                                   uniqueness: {
                                     scope: :examiner_profile_id,
                                     conditions: -> { where(deleted_at: nil) }
                                   }
  validate :evaluation_target_is_active
  validate :examiner_profile_is_active

  scope :active, -> { where(active: true) }

  private

  def evaluation_target_is_active
    return if evaluation_target&.active?

    errors.add(:evaluation_target, "must be active")
  end

  def examiner_profile_is_active
    return if examiner_profile&.active?

    errors.add(:examiner_profile, "must be active")
  end
end
