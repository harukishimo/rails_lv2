class ExaminerSkillCapability < ApplicationRecord
  belongs_to :examiner_profile

  validates :evaluation_target_id, presence: true, uniqueness: { scope: :examiner_profile_id }

  scope :active, -> { where(active: true) }
end
