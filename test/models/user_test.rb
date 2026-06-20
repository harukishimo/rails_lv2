require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "devise authenticates a valid password" do
    user = User.create!(
      name: "Candidate",
      email: "candidate-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    assert user.valid_password?("password123")
    assert_not user.valid_password?("wrong-password")
  end

  test "inactive users cannot authenticate" do
    user = User.create!(
      name: "Inactive",
      email: "inactive@example.com",
      password: "password123",
      password_confirmation: "password123",
      active: false
    )

    assert_not user.active_for_authentication?
  end
end
