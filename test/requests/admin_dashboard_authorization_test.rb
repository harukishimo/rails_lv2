require "test_helper"

class AdminDashboardAuthorizationTest < ActionDispatch::IntegrationTest
  test "admin can access admin dashboard" do
    user = create_user_with_role(Role::ADMIN)

    sign_in_as(user)
    get admin_dashboard_path

    assert_response :success
    assert_equal "Admin dashboard", response.body
  end

  test "candidate is forbidden from admin dashboard" do
    user = create_user_with_role(Role::CANDIDATE)

    sign_in_as(user)
    get admin_dashboard_path

    assert_response :forbidden
  end

  test "examiner is forbidden from admin dashboard" do
    user = create_user_with_role(Role::EXAMINER)

    sign_in_as(user)
    get admin_dashboard_path

    assert_response :forbidden
  end

  test "unauthenticated user is redirected to sign in" do
    get admin_dashboard_path

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  private

  def create_user_with_role(code)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    user = User.create!(
      name: "User",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    user
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
