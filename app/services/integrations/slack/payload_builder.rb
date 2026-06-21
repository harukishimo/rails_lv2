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
        return interview_confirmed_text if status_change_event.event_type == "interview_confirmed"

        [
          "[SkillEvidenceHub] #{status_change_event.localized_event_type}",
          status_change_event.localized_message,
          status_change_event.target_path
        ].compact_blank.join("\n")
      end

      def interview_confirmed_text
        metadata = status_change_event.metadata || {}
        [
          "面談が確定しました！",
          "受験者：#{metadata.fetch('candidate_name', '未設定')}",
          "言語：#{metadata.fetch('skill_name', '未設定')}",
          "lv : #{metadata.fetch('skill_level', '未設定')}",
          "試験官: #{Array(metadata.fetch('examiner_names', [])).join('、').presence || '未設定'}"
        ].join("\n")
      end
    end
  end
end
