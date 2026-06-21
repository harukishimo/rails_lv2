require "test_helper"

class CalendarEventCreateJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @original_client_factory = CalendarEventCreateJob.client_factory
  end

  teardown do
    CalendarEventCreateJob.client_factory = @original_client_factory
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "creates calendar event through job and marks schedule idempotently" do
    schedule, examiner = create_approved_schedule

    assert_enqueued_with(job: SlackDeliveryJob) do
      CalendarEventCreateJob.perform_now(schedule.id, actor_id: examiner.id)
    end

    assert schedule.reload.calendar_created?
    assert_match(/\Aseh[0-9a-f]{24}\z/, schedule.google_calendar_event_id)
    assert_nil schedule.calendar_error_message
    assert schedule.interview_application.reload.calendar_created?
    event = StatusChangeEvent.where(subject: schedule.interview_application).order(:id).last
    assert_equal "interview_application_calendar_created", event.event_type
    assert_equal "scheduled", event.from_status
    assert_equal "calendar_created", event.to_status
  end

  test "does not create duplicate calendar event when job is repeated" do
    schedule, examiner = create_approved_schedule
    client = CountingCalendarClient.new
    CalendarEventCreateJob.client_factory = -> { client }

    CalendarEventCreateJob.perform_now(schedule.id, actor_id: examiner.id)
    CalendarEventCreateJob.perform_now(schedule.id, actor_id: examiner.id)

    assert_equal 1, client.calls
    assert schedule.reload.calendar_created?
    assert_equal "calendar-1", schedule.google_calendar_event_id
  end

  test "treats google calendar conflict as existing deterministic event" do
    schedule, = create_approved_schedule
    api_url = "https://calendar.example.test/events"
    stub_request(:post, api_url).to_return(status: 409, body: JSON.generate(error: "already exists"))
    CalendarEventCreateJob.client_factory = -> {
      Integrations::Calendar::FaradayClient.new(api_url: api_url, access_token: "calendar-token-123")
    }

    CalendarEventCreateJob.perform_now(schedule.id)

    assert schedule.reload.calendar_created?
    assert_match(/\Aseh[0-9a-f]{24}\z/, schedule.google_calendar_event_id)
    assert_nil schedule.calendar_error_message
  end

  test "does not call client when schedule already has calendar event id" do
    schedule, = create_approved_schedule
    schedule.update!(google_calendar_event_id: "existing-calendar-id")
    client = CountingCalendarClient.new
    CalendarEventCreateJob.client_factory = -> { client }

    CalendarEventCreateJob.perform_now(schedule.id)

    assert_equal 0, client.calls
    assert_equal "existing-calendar-id", schedule.reload.google_calendar_event_id
  end

  test "does not call client when interview already completed" do
    schedule, = create_approved_schedule
    schedule.interview_application.update!(status: :completed)
    client = CountingCalendarClient.new
    CalendarEventCreateJob.client_factory = -> { client }

    CalendarEventCreateJob.perform_now(schedule.id)

    assert_equal 0, client.calls
    assert_nil schedule.reload.google_calendar_event_id
  end

  test "records retryable timeout and enqueues retry" do
    schedule, = create_approved_schedule
    api_url = "https://calendar.example.test/events"
    stub_request(:post, api_url).to_timeout
    CalendarEventCreateJob.client_factory = -> {
      Integrations::Calendar::FaradayClient.new(api_url: api_url, access_token: "calendar-token-123")
    }

    assert_enqueued_with(job: CalendarEventCreateJob) do
      CalendarEventCreateJob.perform_now(schedule.id)
    end

    assert schedule.reload.approved?
    assert_nil schedule.google_calendar_event_id
    assert schedule.calendar_error_message.present?
  end

  test "records retryable 429 and enqueues retry" do
    schedule, = create_approved_schedule
    api_url = "https://calendar.example.test/events"
    stub_request(:post, api_url).to_return(status: 429, body: "rate limited")
    CalendarEventCreateJob.client_factory = -> {
      Integrations::Calendar::FaradayClient.new(api_url: api_url, access_token: "calendar-token-123")
    }

    assert_enqueued_with(job: CalendarEventCreateJob) do
      CalendarEventCreateJob.perform_now(schedule.id)
    end

    assert schedule.reload.approved?
    assert_nil schedule.google_calendar_event_id
    assert_match(/external service returned 429/, schedule.calendar_error_message)
  end

  test "redacts configured token from calendar failure message" do
    schedule, = create_approved_schedule
    secret = "calendar-token-secret-123"
    previous_token = ENV["GOOGLE_CALENDAR_ACCESS_TOKEN"]
    ENV["GOOGLE_CALENDAR_ACCESS_TOKEN"] = secret
    CalendarEventCreateJob.client_factory = -> { SecretLeakingCalendarClient.new(secret) }

    assert_enqueued_with(job: CalendarEventCreateJob) do
      CalendarEventCreateJob.perform_now(schedule.id)
    end

    assert schedule.reload.approved?
    assert_not_includes schedule.calendar_error_message, secret
    assert_includes schedule.calendar_error_message, "[FILTERED]"
  ensure
    ENV["GOOGLE_CALENDAR_ACCESS_TOKEN"] = previous_token
  end

  private

  class CountingCalendarClient
    attr_reader :calls

    def initialize
      @calls = 0
    end

    def create_event(payload:)
      @calls += 1
      Integrations::Response.new(status: 200, body: "ok", external_id: "calendar-#{calls}")
    end
  end

  class SecretLeakingCalendarClient
    def initialize(secret)
      @secret = secret
    end

    def create_event(payload:)
      raise Integrations::RetryableError, "calendar token #{@secret} timed out"
    end
  end

  def create_approved_schedule
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
    examiner = create_examiner_for(exam_application.evaluation_target)
    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: examiner,
      examiner_profile: examiner.examiner_profile
    )
    schedule = InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: candidate,
      attributes: {
        starts_at: 2.days.from_now,
        ends_at: 2.days.from_now + 30.minutes
      }
    )
    InterviewSchedules::ApproveService.call(interview_schedule: schedule, actor: examiner)

    [ schedule.reload, examiner ]
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
