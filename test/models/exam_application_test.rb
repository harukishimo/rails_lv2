require "test_helper"

class ExamApplicationTest < ActiveSupport::TestCase
  test "declared exam application belongs to candidate period and target" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target

    application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: period,
      evaluation_target: target,
      actor: candidate
    )

    assert application.declared?
    assert_equal "none", application.result
    assert_equal 1, application.attempt_number
    assert_not_nil application.declared_at
    assert_equal candidate, application.candidate
    assert_equal period, application.evaluation_period
    assert_equal target, application.evaluation_target
  end

  test "prevents duplicate open exam application for same period candidate and target" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target
    create_declared_application(candidate: candidate, period: period, target: target)

    duplicate = ExamApplication.new(
      candidate: candidate,
      evaluation_period: period,
      evaluation_target: target,
      attempt_number: 2,
      status: :declared,
      declared_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "open exam application already exists for this candidate and target"
  end

  test "database rejects duplicate active identity" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target
    application = create_declared_application(candidate: candidate, period: period, target: target)

    error = assert_raises(ActiveRecord::RecordNotUnique) do
      ExamApplication.insert_all!([
        insert_attributes_for(
          candidate: candidate,
          period: period,
          target: target,
          attempt_number: application.attempt_number,
          status: :closed,
          closed_at: Time.current
        )
      ])
    end

    assert_match(/evaluation_period_id, exam_applications.candidate_id, exam_applications.evaluation_target_id/, error.message)
    assert_match(/attempt_number/, error.message)
  end

  test "database rejects duplicate open identity" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target
    create_declared_application(candidate: candidate, period: period, target: target)

    error = assert_raises(ActiveRecord::RecordNotUnique) do
      ExamApplication.insert_all!([
        insert_attributes_for(
          candidate: candidate,
          period: period,
          target: target,
          attempt_number: 2,
          status: :declared
        )
      ])
    end

    assert_match(/evaluation_period_id, exam_applications.candidate_id, exam_applications.evaluation_target_id/, error.message)
  end

  test "next attempt can be created after previous application is closed" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target
    application = create_declared_application(candidate: candidate, period: period, target: target)
    ExamApplications::TransitionService.new(application, actor: candidate).close!

    next_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: period,
      evaluation_target: target,
      actor: candidate
    )

    assert_equal 2, next_application.attempt_number
    assert next_application.declared?
  end

  test "requires candidate role" do
    user = create_user_with_role(Role::EXAMINER)
    application = ExamApplication.new(
      candidate: user,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      attempt_number: 1
    )

    assert_not application.valid?
    assert_includes application.errors[:candidate], "must have candidate role"
  end

  test "requires active target and current active period on create" do
    candidate = create_user_with_role(Role::CANDIDATE)
    inactive_target = create_evaluation_target(active: false)
    past_period = create_evaluation_period(
      starts_on: Date.current - 10.days,
      ends_on: Date.current - 5.days
    )

    application = ExamApplication.new(
      candidate: candidate,
      evaluation_period: past_period,
      evaluation_target: inactive_target,
      attempt_number: 1
    )

    assert_not application.valid?
    assert_includes application.errors[:evaluation_target], "must be active"
    assert_includes application.errors[:evaluation_period], "must include today"
  end

  test "restore does not create duplicate open exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target
    deleted_application = create_declared_application(candidate: candidate, period: period, target: target)
    deleted_application.destroy
    create_declared_application(candidate: candidate, period: period, target: target)

    assert_no_difference -> { ExamApplication.where(candidate: candidate, evaluation_period: period, evaluation_target: target).count } do
      deleted_application.restore(recursive: false)
    end
    assert deleted_application.reload.deleted?
    assert_includes deleted_application.errors[:base], "cannot restore because open exam application already exists"
  end

  private

  def create_declared_application(candidate:, period:, target:)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: period,
      evaluation_target: target,
      actor: candidate
    )
  end

  def create_evaluation_period(attributes = {})
    defaults = {
      name: "Period #{SecureRandom.hex(4)}",
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year,
      active: true
    }.merge(attributes)

    EvaluationPeriod.create!(defaults)
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

  def insert_attributes_for(candidate:, period:, target:, attempt_number:, status:, closed_at: nil)
    now = Time.current

    {
      candidate_id: candidate.id,
      evaluation_period_id: period.id,
      evaluation_target_id: target.id,
      attempt_number: attempt_number,
      status: ExamApplication.statuses.fetch(status.to_s),
      declared_at: now,
      closed_at: closed_at,
      result: ExamApplication.results.fetch("none"),
      lock_version: 0,
      created_at: now,
      updated_at: now
    }
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
