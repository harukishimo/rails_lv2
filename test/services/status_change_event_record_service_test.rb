require "test_helper"

class StatusChangeEventRecordServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "records status change event and audit log" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_exam_application(candidate: candidate)

    assert_difference -> { StatusChangeEvent.where(subject: exam_application).count }, 1 do
      assert_difference -> { AuditLog.where(auditable: exam_application).count }, 1 do
        StatusChangeEvents::RecordService.call(
          subject: exam_application,
          actor: candidate,
          from_status: "draft",
          to_status: "declared",
          event_type: "exam_application_declared",
          message: "Exam application declared",
          target_path: "/exam_applications/#{exam_application.id}",
          metadata: { "exam_application_id" => exam_application.id }
        )
      end
    end

    event = StatusChangeEvent.where(subject: exam_application).recent.first
    audit_log = AuditLog.where(auditable: exam_application).recent.first
    assert_equal "exam_application_declared", event.event_type
    assert_equal "status_change_event.recorded", audit_log.action
    assert_equal "draft", audit_log.before_changes.fetch("status")
    assert_equal "declared", audit_log.after_changes.fetch("status")
    assert_equal event.id, audit_log.after_changes.fetch("status_change_event_id")
  end

  test "redacts metadata in event and audit log" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_exam_application(candidate: candidate)
    secret = "status-event-secret-123"
    previous_secret = ENV["STATUS_EVENT_SECRET"]
    ENV["STATUS_EVENT_SECRET"] = secret

    StatusChangeEvents::RecordService.call(
      subject: exam_application,
      actor: candidate,
      from_status: "draft",
      to_status: "declared",
      event_type: "exam_application_declared",
      message: "Exam application declared",
      target_path: "/exam_applications/#{exam_application.id}",
      metadata: { "secret" => secret }
    )

    event = StatusChangeEvent.where(subject: exam_application).recent.first
    audit_log = AuditLog.where(auditable: exam_application).recent.first
    assert_equal "[FILTERED]", event.metadata.fetch("secret")
    assert_equal "[FILTERED]", audit_log.after_changes.fetch("metadata").fetch("secret")
    assert_not_includes event.metadata.to_json, secret
    assert_not_includes audit_log.after_changes.to_json, secret
  ensure
    ENV["STATUS_EVENT_SECRET"] = previous_secret
  end

  test "does not persist status event audit log or slack job when transaction rolls back" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_exam_application(candidate: candidate)

    assert_no_enqueued_jobs do
      assert_no_difference -> { StatusChangeEvent.count } do
        assert_no_difference -> { AuditLog.count } do
          ExamApplication.transaction do
            StatusChangeEvents::RecordService.call(
              subject: exam_application,
              actor: candidate,
              from_status: "draft",
              to_status: "declared",
              event_type: "exam_application_declared",
              message: "Exam application declared",
              target_path: "/exam_applications/#{exam_application.id}",
              metadata: {}
            )
            raise ActiveRecord::Rollback
          end
        end
      end
    end
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
