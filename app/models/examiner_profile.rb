class ExaminerProfile < ApplicationRecord
  belongs_to :user
  has_many :examiner_skill_capabilities, dependent: :destroy

  validates :display_name, presence: true
  validates :user_id, uniqueness: true
  validate :user_has_examiner_role

  scope :active, -> { where(active: true) }

  def can_evaluate?(evaluation_target)
    return false unless active?

    target_id = evaluation_target.respond_to?(:id) ? evaluation_target.id : evaluation_target
    examiner_skill_capabilities.active.exists?(evaluation_target_id: target_id)
  end

  private

  def user_has_examiner_role
    return if user&.examiner?

    errors.add(:user, "must have examiner role")
  end
end
