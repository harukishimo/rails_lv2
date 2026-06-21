module Integrations
  module Slack
    class PayloadBuilder
      def self.call(status_change_event)
        new(status_change_event).call
      end

      def initialize(status_change_event)
        @status_change_event = status_change_event
      end

      def call
        {
          text: text,
          event_type: status_change_event.event_type,
          subject: {
            type: status_change_event.subject_type,
            id: status_change_event.subject_id
          },
          status: {
            from: status_change_event.from_status,
            to: status_change_event.to_status
          },
          target_path: status_change_event.target_path,
          metadata: Integrations::SecretRedactor.call(status_change_event.metadata || {})
        }
      end

      private

      attr_reader :status_change_event

      def text
        [
          "[SkillEvidenceHub] #{status_change_event.event_type}",
          status_change_event.message,
          status_change_event.target_path
        ].compact_blank.join("\n")
      end
    end
  end
end
