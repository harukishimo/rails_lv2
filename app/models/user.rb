class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  has_many :refresh_tokens, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_many :audit_logs, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify
  has_one :examiner_profile, dependent: :destroy
  has_many :exam_applications, foreign_key: :candidate_id, inverse_of: :candidate, dependent: :restrict_with_error
  has_many :review_comments, foreign_key: :examiner_id, inverse_of: :examiner, dependent: :restrict_with_error
  has_many :review_decisions, foreign_key: :examiner_id, inverse_of: :examiner, dependent: :restrict_with_error
  has_many :interview_results, foreign_key: :examiner_id, inverse_of: :examiner, dependent: :restrict_with_error
  has_many :user_qualifications, dependent: :restrict_with_error
  has_many :granted_user_qualifications,
           class_name: "UserQualification",
           foreign_key: :granted_by_id,
           inverse_of: :granted_by,
           dependent: :restrict_with_error
  has_many :status_change_events, foreign_key: :actor_id, inverse_of: :actor, dependent: :nullify
  has_many :assignment_overridden_interview_applications,
           class_name: "InterviewApplication",
           foreign_key: :assignment_overridden_by_id,
           inverse_of: :assignment_overridden_by,
           dependent: :restrict_with_error

  validates :name, presence: true

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :inactive
  end

  def has_role?(code)
    roles.active.exists?(code: code.to_s)
  end

  def admin?
    has_role?(Role::ADMIN)
  end

  def candidate?
    has_role?(Role::CANDIDATE)
  end

  def examiner?
    has_role?(Role::EXAMINER)
  end
end
