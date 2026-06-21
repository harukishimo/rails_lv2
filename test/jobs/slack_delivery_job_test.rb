require "test_helper"

class SlackDeliveryJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @original_client_factory = SlackDeliveryJob.client_factory
  end

  teardown do
    SlackDeliveryJob.client_factory = @original_client_factory
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "creates succeeded delivery from status change event" do
    event = create_status_change_event
    client = SuccessSlackClient.new
    SlackDeliveryJob.client_factory = ->(webhook_name:) { client }

    assert_difference -> { SlackDelivery.count }, 1 do
      SlackDeliveryJob.perform_now(event.id)
    end

    delivery = slack_delivery_for(event)
    assert delivery.delivery_succeeded?
    assert_equal "default", delivery.webhook_name
    assert_equal "review_application_submitted", delivery.payload.fetch("event_type")
    assert_includes delivery.payload.fetch("text"), "[SkillEvidenceHub] レビュー提出"
    assert_includes delivery.payload.fetch("text"), "受験を下書きから受験表明済みへ変更しました"
    assert_equal 200, delivery.response_code
    assert_equal 0, delivery.retry_count
    assert_equal [ "review_application_submitted" ], client.payloads.map { |payload| payload.fetch("event_type") }
  end

  test "renders interview confirmed message for slack channel" do
    event = create_interview_confirmed_event
    client = SuccessSlackClient.new
    SlackDeliveryJob.client_factory = ->(webhook_name:) { client }

    SlackDeliveryJob.perform_now(event.id)

    delivery = slack_delivery_for(event)
    assert delivery.delivery_succeeded?
    assert_equal <<~TEXT.chomp, delivery.payload.fetch("text")
      面談が確定しました！
      受験者：佐藤 候補
      言語：Rails
      lv : 2
      試験官: 試験官1、試験官2
    TEXT
  end

  test "does not send again when delivery already succeeded" do
    event = create_status_change_event
    client = SuccessSlackClient.new
    SlackDeliveryJob.client_factory = ->(webhook_name:) { client }

    SlackDeliveryJob.perform_now(event.id)

    assert_no_difference -> { SlackDelivery.count } do
      SlackDeliveryJob.perform_now(event.id)
    end

    assert_equal 1, client.payloads.size
    assert SlackDelivery.last.delivery_succeeded?
  end

  test "records retryable 5xx failure and enqueues retry" do
    event = create_status_change_event
    webhook_url = "https://hooks.example.test/services/team/channel/token"
    stub_request(:post, webhook_url).to_return(status: 503, body: "temporary outage")
    SlackDeliveryJob.client_factory = ->(webhook_name:) {
      Integrations::Slack::FaradayClient.new(webhook_url: webhook_url)
    }

    assert_enqueued_with(job: SlackDeliveryJob) do
      SlackDeliveryJob.perform_now(event.id)
    end

    delivery = slack_delivery_for(event)
    assert delivery.delivery_failed?
    assert_equal 503, delivery.response_code
    assert_equal "temporary outage", delivery.response_body
    assert_equal 1, delivery.retry_count
    assert_match(/external service returned 503/, delivery.error_message)
  end

  test "redacts configured secret from failed delivery message" do
    event = create_status_change_event
    secret = "https://hooks.slack.example/very-secret-token"
    previous_secret = ENV["SLACK_WEBHOOK_URL"]
    ENV["SLACK_WEBHOOK_URL"] = secret
    SlackDeliveryJob.client_factory = ->(webhook_name:) { SecretLeakingSlackClient.new(secret) }

    assert_enqueued_with(job: SlackDeliveryJob) do
      SlackDeliveryJob.perform_now(event.id)
    end

    delivery = slack_delivery_for(event)
    assert delivery.delivery_failed?
    assert_equal 1, delivery.retry_count
    assert_equal "review_application_submitted", delivery.payload.fetch("event_type")
    assert_not_includes delivery.error_message, secret
    assert_not_includes delivery.response_body, secret
    assert_includes delivery.error_message, "[FILTERED]"
    assert_includes delivery.response_body, "[FILTERED]"
  ensure
    ENV["SLACK_WEBHOOK_URL"] = previous_secret
  end

  test "redacts configured secret from status metadata and slack payload" do
    secret = "status-secret-token-123"
    previous_secret = ENV["STATUS_SECRET_TOKEN"]
    ENV["STATUS_SECRET_TOKEN"] = secret
    event = create_status_change_event(metadata: { "token" => secret, "safe_id" => 12 })
    client = SuccessSlackClient.new
    SlackDeliveryJob.client_factory = ->(webhook_name:) { client }

    SlackDeliveryJob.perform_now(event.id)

    event.reload
    delivery = slack_delivery_for(event)
    assert_equal "[FILTERED]", event.metadata.fetch("token")
    assert_equal 12, event.metadata.fetch("safe_id")
    assert_equal "[FILTERED]", delivery.payload.fetch("metadata").fetch("token")
    assert_equal 12, delivery.payload.fetch("metadata").fetch("safe_id")
  ensure
    ENV["STATUS_SECRET_TOKEN"] = previous_secret
  end

  private

  class SuccessSlackClient
    attr_reader :payloads

    def initialize
      @payloads = []
    end

    def post(payload:)
      payloads << payload
      Integrations::Response.new(status: 200, body: "ok", external_id: nil)
    end
  end

  class SecretLeakingSlackClient
    def initialize(secret)
      @secret = secret
    end

    def post(payload:)
      raise Integrations::RetryableError.new(
        "timeout while posting to #{@secret}",
        status: 503,
        body: "upstream echoed #{@secret}"
      )
    end
  end

  def slack_delivery_for(event)
    SlackDelivery.find_by!(status_change_event: event, webhook_name: "default")
  end

  def create_status_change_event(metadata: { exam_application_id: nil })
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )

    StatusChangeEvents::RecordService.call(
      subject: exam_application,
      actor: candidate,
      from_status: "draft",
      to_status: "declared",
      event_type: "review_application_submitted",
      message: "Review application submitted",
      target_path: "/exam_applications/#{exam_application.id}",
      metadata: metadata.fetch(:exam_application_id, nil) ? metadata : metadata.merge(exam_application_id: exam_application.id)
    )
  end

  def create_interview_confirmed_event
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )

    StatusChangeEvent.create!(
      subject: exam_application,
      actor: candidate,
      from_status: nil,
      to_status: "interview_confirmed",
      event_type: "interview_confirmed",
      message: "面談が確定しました！",
      target_path: "/interview_applications/1",
      metadata: {
        candidate_name: "佐藤 候補",
        skill_name: "Rails",
        skill_level: 2,
        examiner_names: [ "試験官1", "試験官2" ]
      }
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
