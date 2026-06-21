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
        record_audit_log(status_change_event)
        SlackDeliveryJob.perform_later(status_change_event.id) if defined?(SlackDeliveryJob)
      end
    end

    private

    attr_reader :subject, :actor, :from_status, :to_status, :event_type, :message, :target_path, :metadata

    def sanitized_metadata
      return metadata unless defined?(Integrations::SecretRedactor)

      Integrations::SecretRedactor.call(metadata)
    end

    def record_audit_log(status_change_event)
      return unless defined?(AuditLogs::RecordService)

      AuditLogs::RecordService.call(
        action: "status_change_event.recorded",
        actor: actor,
        auditable: subject,
        before_changes: { status: from_status },
        after_changes: {
          status: to_status,
          event_type: event_type,
          status_change_event_id: status_change_event.id,
          target_path: target_path,
          metadata: sanitized_metadata
        }
      )
    end
  end
end
