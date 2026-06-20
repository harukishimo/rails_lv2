require "test_helper"

class ExaminerProfileTest < ActiveSupport::TestCase
  EvaluationTargetStub = Struct.new(:id)

  test "examiner profile requires examiner role" do
    user = create_user_with_role(Role::CANDIDATE)
    profile = ExaminerProfile.new(user: user, display_name: "Candidate")

    assert_not profile.valid?
    assert_includes profile.errors[:user], "must have examiner role"
  end

  test "examiner can evaluate active assigned target" do
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target_id: 101)

    assert profile.can_evaluate?(EvaluationTargetStub.new(101))
    assert_not profile.can_evaluate?(EvaluationTargetStub.new(202))
  end

  test "inactive capability does not allow evaluation" do
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target_id: 101, active: false)

    assert_not profile.can_evaluate?(101)
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
