require "test_helper"

class RefreshTokenTest < ActiveSupport::TestCase
  test "issues an opaque refresh token and stores only the digest" do
    user = create_user

    record, raw_token = RefreshToken.issue_for!(user)

    assert record.persisted?
    assert_not_equal raw_token, record.token_digest
    assert_equal record, RefreshToken.authenticate(raw_token)
  end

  test "rotates refresh token and revokes the old token" do
    user = create_user
    old_record, old_raw_token = RefreshToken.issue_for!(user)

    new_record, new_raw_token = RefreshToken.rotate!(old_raw_token)

    assert old_record.reload.revoked_at.present?
    assert_nil RefreshToken.authenticate(old_raw_token)
    assert_equal new_record, RefreshToken.authenticate(new_raw_token)
  end

  test "expired refresh tokens are not authenticated" do
    user = create_user
    _record, raw_token = RefreshToken.issue_for!(user, expires_at: 1.minute.ago)

    assert_nil RefreshToken.authenticate(raw_token)
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
