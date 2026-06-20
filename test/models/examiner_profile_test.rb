require "test_helper"

class ExaminerProfileTest < ActiveSupport::TestCase
  test "examiner profile requires examiner role" do
    user = create_user_with_role(Role::CANDIDATE)
    profile = ExaminerProfile.new(user: user, display_name: "Candidate")

    assert_not profile.valid?
    assert_includes profile.errors[:user], "must have examiner role"
  end

  test "examiner can evaluate active assigned target" do
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner")
    target = create_evaluation_target
    other_target = create_evaluation_target

    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: target)

    assert profile.can_evaluate?(target)
    assert_not profile.can_evaluate?(other_target)
  end

  test "inactive capability does not allow evaluation" do
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner")
    target = create_evaluation_target
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: target, active: false)

    assert_not profile.can_evaluate?(target)
  end

  test "destroy soft deletes profile and capabilities" do
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner")
    target = create_evaluation_target
    capability = ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: target)

    profile.destroy

    assert_not ExaminerProfile.exists?(profile.id)
    assert ExaminerProfile.with_deleted.exists?(profile.id)
    assert_not ExaminerSkillCapability.exists?(capability.id)
    assert ExaminerSkillCapability.with_deleted.exists?(capability.id)
  end

  test "profile can be recreated for same user after soft delete" do
    examiner = create_user_with_role(Role::EXAMINER)
    ExaminerProfile.create!(user: examiner, display_name: "Examiner").destroy

    recreated = ExaminerProfile.create!(user: examiner, display_name: "Examiner Again")

    assert recreated.persisted?
  end

  test "profile restore does not create active duplicate for same user" do
    examiner = create_user_with_role(Role::EXAMINER)
    deleted_profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner")
    deleted_profile.destroy
    ExaminerProfile.create!(user: examiner, display_name: "Examiner Again")

    assert_no_difference -> { ExaminerProfile.where(user: examiner).count } do
      deleted_profile.restore(recursive: false)
    end
    assert deleted_profile.reload.deleted?
    assert_includes deleted_profile.errors[:base], "cannot restore because active duplicate exists"
  end

  private

  def create_evaluation_target
    language = ProgrammingLanguage.create!(name: "Ruby #{SecureRandom.hex(4)}")
    framework = Framework.create!(name: "Ruby on Rails #{SecureRandom.hex(4)}", programming_language: language)

    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv#{rand(1000..9999)}", numeric_level: 2),
      external_knowledge_key: "ruby_on_rails_lv2_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}"
    )
  end

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
