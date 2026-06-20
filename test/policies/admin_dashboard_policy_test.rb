require "test_helper"

class AdminDashboardPolicyTest < ActiveSupport::TestCase
  test "admin can view admin dashboard" do
    user = create_user_with_role(Role::ADMIN)

    assert AdminDashboardPolicy.new(user, :admin_dashboard).show?
  end

  test "candidate cannot view admin dashboard" do
    user = create_user_with_role(Role::CANDIDATE)

    assert_not AdminDashboardPolicy.new(user, :admin_dashboard).show?
  end

  test "examiner cannot view admin dashboard" do
    user = create_user_with_role(Role::EXAMINER)

    assert_not AdminDashboardPolicy.new(user, :admin_dashboard).show?
  end

  test "inactive admin cannot view admin dashboard" do
    user = create_user_with_role(Role::ADMIN)
    user.update!(active: false)

    assert_not AdminDashboardPolicy.new(user, :admin_dashboard).show?
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
end
