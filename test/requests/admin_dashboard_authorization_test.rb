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

  test "forbidden admin dashboard access is logged for audit" do
    user = create_user_with_role(Role::CANDIDATE)

    sign_in_as(user)
    logs = nil
    assert_difference -> { AuditLog.where(action: "authorization.denied", actor: user).count }, 1 do
      logs = capture_rails_logs do
        get admin_dashboard_path
      end
    end

    assert_response :forbidden
    assert_includes logs, "pundit.authorization_denied"
    assert_includes logs, "\"user_id\":#{user.id}"
    assert_includes logs, "\"policy\":\"AdminDashboardPolicy\""
    assert_includes logs, "\"query\":\"show?\""
    assert_includes logs, "\"record\":\"admin_dashboard\""
    assert_not_includes logs, user.email
    audit_log = AuditLog.where(action: "authorization.denied", actor: user).recent.first
    assert_equal "AdminDashboardPolicy", audit_log.after_changes.fetch("policy")
    assert_equal "show?", audit_log.after_changes.fetch("query")
    assert_equal "admin_dashboard", audit_log.after_changes.fetch("record")
    assert_equal admin_dashboard_path, audit_log.after_changes.fetch("path")
    assert_not_includes audit_log.after_changes.to_json, user.email
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

  def capture_rails_logs
    output = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(output))

    yield

    output.string
  ensure
    Rails.logger = previous_logger
  end
end
