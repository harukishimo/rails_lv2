require "test_helper"

class ExaminerSkillCapabilityTest < ActiveSupport::TestCase
  test "connects an active examiner profile to an active evaluation target" do
    profile = create_examiner_profile
    target = create_evaluation_target

    capability = ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: target)

    assert capability.active?
    assert_includes profile.evaluation_targets, target
  end

  test "prevents duplicate capability for the same profile and target" do
    profile = create_examiner_profile
    target = create_evaluation_target
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: target)

    duplicate = ExaminerSkillCapability.new(examiner_profile: profile, evaluation_target: target)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:evaluation_target_id], "has already been taken"
  end

  test "requires active evaluation target" do
    profile = create_examiner_profile
    target = create_evaluation_target(active: false)
    capability = ExaminerSkillCapability.new(examiner_profile: profile, evaluation_target: target)

    assert_not capability.valid?
    assert_includes capability.errors[:evaluation_target], "must be active"
  end

  private

  def create_examiner_profile
    user = create_user_with_role(Role::EXAMINER)
    ExaminerProfile.create!(user: user, display_name: "Examiner")
  end

  def create_evaluation_target(attributes = {})
    language = ProgrammingLanguage.create!(name: "Ruby #{SecureRandom.hex(4)}")
    framework = Framework.create!(name: "Ruby on Rails #{SecureRandom.hex(4)}", programming_language: language)

    EvaluationTarget.create!({
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv#{rand(1000..9999)}", numeric_level: 2),
      external_knowledge_key: "ruby_on_rails_lv2_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}"
    }.merge(attributes))
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
