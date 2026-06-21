class CalendarEventCreateJob < ApplicationJob
  queue_as :default

  class_attribute :client_factory, default: -> { Integrations::Calendar::ClientFactory.build }

  retry_on Integrations::RetryableError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(interview_schedule_id, actor_id: nil)
    interview_schedule = InterviewSchedule.find(interview_schedule_id)
    persist_with_lock!(interview_schedule, actor_id)
  rescue Integrations::RetryableError => error
    persist_failure!(interview_schedule, error) if defined?(interview_schedule) && interview_schedule
    raise retryable_error_for_retry(error)
  rescue Integrations::NonRetryableError => error
    persist_failure!(interview_schedule, error) if defined?(interview_schedule) && interview_schedule
  end

  private

  def persist_with_lock!(interview_schedule, actor_id)
    interview_schedule.with_lock do
      return interview_schedule if interview_schedule.google_calendar_event_id.present?
      return interview_schedule if interview_schedule.interview_application.completed?

      validate_schedule!(interview_schedule)

      payload = Integrations::Calendar::EventPayload.call(interview_schedule)
      response = client_factory.call.create_event(payload: payload)
      persist_success!(interview_schedule, response, actor_id)
    end
  end

  def validate_schedule!(interview_schedule)
    return if interview_schedule.approved?

    raise Integrations::NonRetryableError, "interview schedule must be approved before calendar creation"
  end

  def persist_success!(interview_schedule, response, actor_id)
    interview_schedule.update!(
      status: :calendar_created,
      google_calendar_event_id: response.external_id.presence || "calendar-#{interview_schedule.id}",
      calendar_error_message: nil
    )
    InterviewApplications::TransitionService.new(
      interview_schedule.interview_application,
      actor: actor_for(actor_id)
    ).create_calendar!
    interview_schedule
  end

  def persist_failure!(interview_schedule, error)
    interview_schedule.update!(calendar_error_message: Integrations::SecretRedactor.call(error.message))
  end

  def actor_for(actor_id)
    User.find_by(id: actor_id) if actor_id.present?
  end

  def retryable_error_for_retry(error)
    Integrations::RetryableError.new(
      Integrations::SecretRedactor.call(error.message),
      status: error.status,
      body: Integrations::SecretRedactor.call(error.body)
    )
  end
end
