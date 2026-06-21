require "test_helper"

class AdminUserManagementPolicyTest < ActiveSupport::TestCase
  test "admin user policy permits only active admin" do
    admin = create_user_with_role(Role::ADMIN)
    candidate = create_user_with_role(Role::CANDIDATE)

    assert Admin::UserPolicy.new(admin, User).index?
    assert_not Admin::UserPolicy.new(candidate, User).index?

    admin.update!(active: false)
    assert_not Admin::UserPolicy.new(admin, User).index?
  end

  test "admin user scope exposes all users only to admin" do
    admin = create_user_with_role(Role::ADMIN)
    candidate = create_user_with_role(Role::CANDIDATE)

    admin_scope = Admin::UserPolicy::Scope.new(admin, User).resolve
    candidate_scope = Admin::UserPolicy::Scope.new(candidate, User).resolve

    assert_includes admin_scope, admin
    assert_includes admin_scope, candidate
    assert_empty candidate_scope
  end

  test "admin examiner profile policy permits only active admin" do
    admin = create_user_with_role(Role::ADMIN)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner")

    assert Admin::ExaminerProfilePolicy.new(admin, profile).index?
    assert_not Admin::ExaminerProfilePolicy.new(examiner, profile).index?
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
