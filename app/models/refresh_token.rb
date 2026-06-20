class RefreshToken < ApplicationRecord
  TOKEN_BYTES = 48
  DEFAULT_TTL = 30.days

  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }

  def self.issue_for!(user, expires_at: DEFAULT_TTL.from_now)
    raw_token = SecureRandom.urlsafe_base64(TOKEN_BYTES)
    record = create!(user: user, token_digest: digest(raw_token), expires_at: expires_at)

    [ record, raw_token ]
  end

  def self.authenticate(raw_token)
    return if raw_token.blank?

    token = active.includes(:user).find_by(token_digest: digest(raw_token))
    token if token&.user&.active_for_authentication?
  end

  def self.rotate!(raw_token)
    return if raw_token.blank?

    transaction do
      token = find_by(token_digest: digest(raw_token))
      next unless token

      token.lock!
      next unless token.active? && token.user.active_for_authentication?

      token.revoke!
      issue_for!(token.user)
    end
  end

  def self.digest(raw_token)
    OpenSSL::Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end
end
