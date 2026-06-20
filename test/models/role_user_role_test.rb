require "test_helper"

class RoleUserRoleTest < ActiveSupport::TestCase
  test "role accepts fixed role codes only" do
    role = Role.find_or_initialize_by(code: Role::ADMIN)
    role.name = Role::NAMES.fetch(Role::ADMIN)

    assert role.valid?

    role.code = "temporary"

    assert_not role.valid?
    assert_includes role.errors[:code], "is not included in the list"
  end

  test "user can have multiple roles through user_roles" do
    user = create_user
    admin = create_role(Role::ADMIN)
    examiner = create_role(Role::EXAMINER)

    user.roles << admin
    user.roles << examiner

    assert user.admin?
    assert user.examiner?
    assert_not user.candidate?
  end

  test "user role assignment is unique per user and role" do
    user = create_user
    role = create_role(Role::CANDIDATE)

    UserRole.create!(user: user, role: role)
    duplicate = UserRole.new(user: user, role: role)

    assert_not duplicate.valid?
  end

  private

  def create_user
    User.create!(
      name: "User",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  def create_role(code)
    Role.find_or_create_by!(code: code) do |role|
      role.name = Role::NAMES.fetch(code)
    end
  end
end
