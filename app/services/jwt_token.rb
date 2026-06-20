class JwtToken
  ALGORITHM = "HS256"
  DEFAULT_TTL = 15.minutes
  TOKEN_TYPE = "access"

  class Error < StandardError; end
  class ExpiredTokenError < Error; end
  class InvalidTokenError < Error; end

  def self.issue_for(user, expires_at: DEFAULT_TTL.from_now)
    payload = {
      sub: user.id,
      exp: expires_at.to_i,
      iat: Time.current.to_i,
      typ: TOKEN_TYPE
    }

    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode!(token)
    payload, = JWT.decode(token, secret, true, { algorithm: ALGORITHM })
    payload.with_indifferent_access
  rescue JWT::ExpiredSignature
    raise ExpiredTokenError, "access token has expired"
  rescue JWT::DecodeError
    raise InvalidTokenError, "access token is invalid"
  end

  def self.user_for(token)
    payload = decode!(token)
    return unless payload[:typ] == TOKEN_TYPE

    User.find_by(id: payload[:sub])
  end

  def self.secret
    Rails.application.secret_key_base
  end
end
