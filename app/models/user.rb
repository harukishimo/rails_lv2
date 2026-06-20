class User < ApplicationRecord
  devise :database_authenticatable, :rememberable, :validatable

  has_many :refresh_tokens, dependent: :destroy

  validates :name, presence: true

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :inactive
  end
end
