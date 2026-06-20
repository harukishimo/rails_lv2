require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  test "default actions are denied" do
    policy = ApplicationPolicy.new(create_user, Object.new)

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "default scope resolves to none" do
    Role.find_or_create_by!(code: Role::ADMIN) do |role|
      role.name = Role::NAMES.fetch(Role::ADMIN)
    end

    resolved = ApplicationPolicy::Scope.new(create_user, Role.all).resolve

    assert_empty resolved
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
end
