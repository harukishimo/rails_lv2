require "test_helper"

class AuditLogTest < ActiveSupport::TestCase
  test "records auditable action with redacted values" do
    actor = create_user_with_role(Role::CANDIDATE)
    auditable = create_exam_application(candidate: actor)
    secret = "audit-secret-token-123"
    previous_secret = ENV["AUDIT_SECRET_TOKEN"]
    ENV["AUDIT_SECRET_TOKEN"] = secret

    audit_log = AuditLogs::RecordService.call(
      action: "example.important_operation",
      actor: actor,
      auditable: auditable,
      ip_address: "127.0.0.1",
      user_agent: "test-agent",
      before_changes: { "token" => secret, "status" => "draft" },
      after_changes: { "token" => secret, "status" => "declared" }
    )

    assert audit_log.persisted?
    assert_equal actor, audit_log.actor
    assert_equal auditable, audit_log.auditable
    assert_equal "example.important_operation", audit_log.action
    assert_equal "[FILTERED]", audit_log.before_changes.fetch("token")
    assert_equal "[FILTERED]", audit_log.after_changes.fetch("token")
    assert_not_includes audit_log.before_changes.to_json, secret
    assert_not_includes audit_log.after_changes.to_json, secret
  ensure
    ENV["AUDIT_SECRET_TOKEN"] = previous_secret
  end

  private

  def create_exam_application(candidate:)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
  end

  def create_evaluation_period
    EvaluationPeriod.create!(
      name: "Period #{SecureRandom.hex(4)}",
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year
    )
  end

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
