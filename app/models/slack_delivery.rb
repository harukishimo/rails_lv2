class SlackDelivery < ApplicationRecord
  acts_as_paranoid

  serialize :payload, coder: JSON

  enum :delivery_status, {
    pending: 0,
    succeeded: 1,
    failed: 2
  }, prefix: :delivery, default: :pending, validate: true

  belongs_to :status_change_event

  validates :status_change_event, presence: true
  validates :webhook_name, presence: true, length: { maximum: 100 }
  validates :retry_count, numericality: { greater_than_or_equal_to: 0 }
  validates :status_change_event_id, uniqueness: { scope: :webhook_name, conditions: -> { where(deleted_at: nil) } }

  def mark_succeeded!(response:)
    update!(
      delivery_status: :succeeded,
      response_code: response.status,
      response_body: Integrations::SecretRedactor.call(response.body),
      delivered_at: Time.current,
      error_message: nil
    )
  end

  def mark_failed!(error:, response_code: nil, response_body: nil, payload: nil, increment_retry_count: false)
    attributes = {
      delivery_status: :failed,
      response_code: response_code,
      response_body: Integrations::SecretRedactor.call(response_body),
      error_message: Integrations::SecretRedactor.call(error.message)
    }
    attributes[:payload] = payload if payload.present?
    attributes[:retry_count] = retry_count + 1 if increment_retry_count

    update!(attributes)
  end
end
