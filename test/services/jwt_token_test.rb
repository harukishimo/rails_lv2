require "test_helper"

class JwtTokenTest < ActiveSupport::TestCase
  test "issues and verifies access tokens with an explicit algorithm" do
    user = create_user

    token = JwtToken.issue_for(user)
    payload = JwtToken.decode!(token)

    assert_equal user.id, payload[:sub]
    assert_equal "access", payload[:typ]
    assert_equal user, JwtToken.user_for(token)
  end

  test "expired access tokens are rejected" do
    user = create_user
    token = JwtToken.issue_for(user, expires_at: 1.minute.ago)

    assert_raises JwtToken::ExpiredTokenError do
      JwtToken.decode!(token)
    end
  end

  test "tampered access tokens are rejected" do
    user = create_user
    token = "#{JwtToken.issue_for(user)}tampered"

    assert_raises JwtToken::InvalidTokenError do
      JwtToken.decode!(token)
    end
  end

  private

  def create_user
    User.create!(
      name: "Candidate",
      email: "candidate-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end
end
