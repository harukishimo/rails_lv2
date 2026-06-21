require "test_helper"

class InterviewApplicationTest < ActiveSupport::TestCase
  test "creates interview application for review approved exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_review_approved_exam_application(candidate: candidate)

    interview_application = InterviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate
    )

    assert interview_application.requested?
    assert_not_nil interview_application.requested_at
    assert_equal "面接官未定", interview_application.assigned_examiner_name
    assert_not interview_application.cancelable?
    assert exam_application.reload.interview_requested?
  end

  test "requires exam application" do
    interview_application = InterviewApplication.new(status: :requested, requested_at: Time.current)

    assert_not interview_application.valid?
    assert_includes interview_application.errors[:exam_application], "must exist"
  end

  test "rejects declared and reviewing exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    declared = create_declared_exam_application(candidate: candidate)
    reviewing = create_declared_exam_application(candidate: candidate)
    reviewing.update!(status: :reviewing)

    declared_error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewApplications::CreateService.call(exam_application: declared, actor: candidate)
    end
    reviewing_error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewApplications::CreateService.call(exam_application: reviewing, actor: candidate)
    end

    assert_includes declared_error.record.errors[:exam_application], "must be permitted for interview"
    assert_includes reviewing_error.record.errors[:exam_application], "must be permitted for interview"
  end

  test "allows review approved exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_approved = create_declared_exam_application(candidate: candidate)
    review_approved.update!(status: :review_approved)

    review_approved_interview = InterviewApplications::CreateService.call(
      exam_application: review_approved,
      actor: candidate
    )
    assert review_approved_interview.requested?
    assert review_approved.reload.interview_requested?
  end

  test "rejects closed exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    ExamApplications::TransitionService.new(exam_application, actor: candidate).close!

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)
    end

    assert_includes error.record.errors[:exam_application], "must be permitted for interview"
  end

  test "prevents duplicate interview application for one exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_review_approved_exam_application(candidate: candidate)
    InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)

    duplicate = InterviewApplication.new(
      exam_application: exam_application,
      status: :requested,
      requested_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:exam_application_id], "has already been taken"
  end

  test "database rejects duplicate active interview application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_review_approved_exam_application(candidate: candidate)
    InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)
    now = Time.current

    assert_raises(ActiveRecord::RecordNotUnique) do
      InterviewApplication.insert_all!([
        {
          exam_application_id: exam_application.id,
          status: InterviewApplication.statuses.fetch("requested"),
          requested_at: now,
          lock_version: 0,
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "accepts result after interview schedule is approved" do
    scheduled = InterviewApplication.new(status: :scheduled)
    calendar_created = InterviewApplication.new(status: :calendar_created)

    assert scheduled.result_decidable?
    assert calendar_created.result_decidable?
  end

  private

  def create_review_approved_exam_application(candidate:)
    create_declared_exam_application(candidate: candidate).tap do |exam_application|
      exam_application.update!(status: :review_approved)
    end
  end

  def create_declared_exam_application(candidate:)
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
