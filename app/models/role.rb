class Role < ApplicationRecord
  ADMIN = "admin"
  CANDIDATE = "candidate"
  EXAMINER = "examiner"
  CODES = [ ADMIN, CANDIDATE, EXAMINER ].freeze
  NAMES = {
    ADMIN => "管理者",
    CANDIDATE => "受験者",
    EXAMINER => "評価官"
  }.freeze

  has_many :user_roles, dependent: :destroy
  has_many :users, through: :user_roles

  validates :code, presence: true, inclusion: { in: CODES }, uniqueness: true
  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
