class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  has_many :refresh_tokens, dependent: :destroy
  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles
  has_one :examiner_profile, dependent: :destroy

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
