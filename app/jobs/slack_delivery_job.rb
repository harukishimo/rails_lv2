class SlackDeliveryJob < ApplicationJob
  queue_as :default

  class_attribute :client_factory, default: ->(webhook_name:) {
    Integrations::Slack::ClientFactory.build(webhook_name: webhook_name)
  }

  retry_on Integrations::RetryableError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveRecord::RecordNotFound

  def perform(status_change_event_id, webhook_name: Integrations::Slack::ClientFactory::DEFAULT_WEBHOOK_NAME)
    status_change_event = StatusChangeEvent.find(status_change_event_id)
    delivery = find_or_create_delivery(status_change_event, webhook_name)
    delivery.with_lock do
      return delivery if delivery.delivery_succeeded?

      prepare_delivery!(delivery, status_change_event)
      response = client_for(webhook_name).post(payload: delivery.payload)
      delivery.mark_succeeded!(response: response)
    end
  rescue Integrations::RetryableError => error
    delivery&.reload
    delivery&.mark_failed!(
      error: error,
      response_code: error.status,
      response_body: error.body,
      payload: payload_for(status_change_event),
      increment_retry_count: true
    )
    raise retryable_error_for_retry(error)
  rescue Integrations::NonRetryableError => error
    delivery&.reload
    delivery&.mark_failed!(
      error: error,
      response_code: error.status,
      response_body: error.body,
      payload: payload_for(status_change_event)
    )
  end

  private

  def find_or_create_delivery(status_change_event, webhook_name)
    SlackDelivery.find_or_create_by!(
      status_change_event: status_change_event,
      webhook_name: webhook_name
    )
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def prepare_delivery!(delivery, status_change_event)
    delivery.update!(
      delivery_status: :pending,
      payload: payload_for(status_change_event)
    )
  end

  def payload_for(status_change_event)
    Integrations::Slack::PayloadBuilder.call(status_change_event)
  end

  def client_for(webhook_name)
    client_factory.call(webhook_name: webhook_name)
  end

  def retryable_error_for_retry(error)
    Integrations::RetryableError.new(
      Integrations::SecretRedactor.call(error.message),
      status: error.status,
      body: Integrations::SecretRedactor.call(error.body)
    )
  end
end
