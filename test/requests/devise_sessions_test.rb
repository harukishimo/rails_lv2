require "test_helper"

class DeviseSessionsTest < ActionDispatch::IntegrationTest
  test "user can sign in and sign out with browser session authentication" do
    user = create_user

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }

    assert_response :see_other
    assert_redirected_to root_path

    delete destroy_user_session_path

    assert_response :see_other
    assert_redirected_to root_path
  end

  test "invalid browser session credentials are rejected" do
    user = create_user

    post user_session_path, params: {
      user: {
        email: user.email,
        password: "wrong-password"
      }
    }

    assert_response :unprocessable_entity
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
