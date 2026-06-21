require "test_helper"

class InterviewScheduleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "creates future requested schedule with default timezone" do
    interview_application = create_interview_application
    starts_at = future_quarter_hour(days: 2)

    schedule = InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: interview_application.exam_application.candidate,
      attributes: {
        starts_at: starts_at,
        ends_at: starts_at + 30.minutes
      }
    )

    assert schedule.requested?
    assert_equal "Asia/Tokyo", schedule.timezone
    assert interview_application.reload.schedule_requested?
    assert_equal "Asia/Tokyo", Time.zone.name
  end

  test "rejects invalid timezone" do
    interview_application = create_interview_application
    starts_at = future_quarter_hour(days: 2)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewSchedules::CreateService.call(
        interview_application: interview_application,
        actor: interview_application.exam_application.candidate,
        attributes: {
          starts_at: starts_at,
          ends_at: starts_at + 30.minutes,
          timezone: "Bad/Zone"
        }
      )
    end

    assert_includes error.record.errors[:timezone], "is invalid"
  end

  test "rejects past starts_at" do
    interview_application = create_interview_application

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewSchedules::CreateService.call(
        interview_application: interview_application,
        actor: interview_application.exam_application.candidate,
        attributes: {
          starts_at: 1.hour.ago,
          ends_at: 30.minutes.ago
        }
      )
    end

    assert_includes error.record.errors[:starts_at], "must be in the future"
  end

  test "rejects starts_at after ends_at" do
    interview_application = create_interview_application
    starts_at = future_quarter_hour(days: 2, hour: 11)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewSchedules::CreateService.call(
        interview_application: interview_application,
        actor: interview_application.exam_application.candidate,
        attributes: {
          starts_at: starts_at,
          ends_at: starts_at - 1.hour
        }
      )
    end

    assert_includes error.record.errors[:starts_at], "must be before ends_at"
  end

  test "rejects schedule times that are not 15 minute increments" do
    interview_application = create_interview_application
    starts_at = future_quarter_hour(days: 2, min: 10)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewSchedules::CreateService.call(
        interview_application: interview_application,
        actor: interview_application.exam_application.candidate,
        attributes: {
          starts_at: starts_at,
          ends_at: starts_at + 30.minutes
        }
      )
    end

    assert_includes error.record.errors[:starts_at], "must be specified in 15-minute increments"
    assert_includes error.record.errors[:ends_at], "must be specified in 15-minute increments"
  end

  test "approves requested schedule and updates interview application status" do
    interview_application = create_interview_application
    schedule = create_schedule(interview_application)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target)

    assert_no_enqueued_jobs only: CalendarEventCreateJob do
      assert_enqueued_with(job: SlackDeliveryJob) do
        InterviewSchedules::ApproveService.call(interview_schedule: schedule, actor: examiner)
      end
    end

    assert schedule.reload.approved?
    assert interview_application.reload.scheduled?
    assert interview_application.exam_application.reload.interview_scheduled?
    assert StatusChangeEvent.where(subject: interview_application, event_type: "interview_confirmed").exists?
  end

  test "rejects requested schedule without scheduling interview application" do
    interview_application = create_interview_application
    schedule = create_schedule(interview_application)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target)

    InterviewSchedules::RejectService.call(interview_schedule: schedule, actor: examiner)

    assert schedule.reload.rejected?
    assert interview_application.reload.schedule_requested?
  end

  private

  def create_schedule(interview_application)
    starts_at = future_quarter_hour(days: 3)
    InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: interview_application.exam_application.candidate,
      attributes: {
        starts_at: starts_at,
        ends_at: starts_at + 30.minutes
      }
    )
  end

  def future_quarter_hour(days:, hour: 10, min: 0)
    Time.zone.local(Date.current.year, Date.current.month, Date.current.day, hour, min, 0) + days.days
  end

  def create_interview_application
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
    exam_application.update!(status: :review_approved)
    interview_application = InterviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate
    )
    assign_examiner(interview_application)
    interview_application
  end

  def assign_examiner(interview_application)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target)
    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: examiner,
      examiner_profile: examiner.examiner_profile
    )
  end

  def create_examiner_for(evaluation_target)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: evaluation_target)
    examiner
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
