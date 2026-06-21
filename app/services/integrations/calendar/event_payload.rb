require "digest"

module Integrations
  module Calendar
    class EventPayload
      def self.call(interview_schedule)
        new(interview_schedule).call
      end

      def initialize(interview_schedule)
        @interview_schedule = interview_schedule
      end

      def call
        {
          idempotency_key: idempotency_key,
          event_id: event_id,
          summary: summary,
          description: description,
          start: {
            date_time: interview_schedule.starts_at.iso8601,
            time_zone: interview_schedule.timezone
          },
          end: {
            date_time: interview_schedule.ends_at.iso8601,
            time_zone: interview_schedule.timezone
          },
          attendees: attendee_emails.map { |email| { email: email } }
        }
      end

      private

      attr_reader :interview_schedule

      def idempotency_key
        "interview_schedule:#{interview_schedule.id}"
      end

      def event_id
        "seh#{Digest::SHA256.hexdigest(idempotency_key)[0, 24]}"
      end

      def summary
        "SkillEvidenceHub 評価面談: #{exam_application.display_name}"
      end

      def description
        "Evaluation interview for #{exam_application.candidate.name} / #{exam_application.evaluation_target.display_name}"
      end

      def attendee_emails
        [
          exam_application.candidate.email,
          assigned_examiner_user&.email
        ].compact
      end

      def assigned_examiner_user
        interview_application.assigned_examiner_profile&.user
      end

      def interview_application
        @interview_application ||= interview_schedule.interview_application
      end

      def exam_application
        @exam_application ||= interview_application.exam_application
      end
    end
  end
end
