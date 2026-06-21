module StatusChangeEvents
  class RecordService
    def self.call(subject:, actor:, from_status:, to_status:, event_type:, message:, target_path:, metadata: {})
      new(
        subject: subject,
        actor: actor,
        from_status: from_status,
        to_status: to_status,
        event_type: event_type,
        message: message,
        target_path: target_path,
        metadata: metadata
      ).call
    end

    def initialize(subject:, actor:, from_status:, to_status:, event_type:, message:, target_path:, metadata: {})
      @subject = subject
      @actor = actor
      @from_status = from_status
      @to_status = to_status
      @event_type = event_type
      @message = message
      @target_path = target_path
      @metadata = metadata
    end

    def call
      StatusChangeEvent.create!(
        subject: subject,
        actor: actor,
        from_status: from_status,
        to_status: to_status,
        event_type: event_type,
        message: message,
        target_path: target_path,
        metadata: sanitized_metadata
      ).tap do |status_change_event|
        SlackDeliveryJob.perform_later(status_change_event.id) if defined?(SlackDeliveryJob)
      end
    end

    private

    attr_reader :subject, :actor, :from_status, :to_status, :event_type, :message, :target_path, :metadata

    def sanitized_metadata
      return metadata unless defined?(Integrations::SecretRedactor)

      Integrations::SecretRedactor.call(metadata)
    end
  end
end
