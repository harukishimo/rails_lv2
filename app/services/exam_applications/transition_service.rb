module ExamApplications
  class TransitionService
    class InvalidTransitionError < StandardError; end

    ALLOWED_TRANSITIONS = {
      "draft" => %w[declared canceled],
      "declared" => %w[reviewing interview_requested canceled closed],
      "reviewing" => %w[review_approved canceled closed],
      "review_approved" => %w[interview_requested canceled closed],
      "interview_requested" => %w[interview_scheduled closed],
      "interview_scheduled" => %w[passed failed closed],
      "passed" => %w[closed],
      "failed" => %w[closed],
      "canceled" => %w[closed],
      "closed" => []
    }.freeze

    def initialize(exam_application, actor:)
      @exam_application = exam_application
      @actor = actor
    end

    def declare!
      transition_to!(:declared, declared_at: Time.current)
    end

    def start_review!
      transition_to!(:reviewing)
    end

    def approve_review!
      transition_to!(:review_approved)
    end

    def request_interview!
      transition_to!(:interview_requested)
    end

    def schedule_interview!
      transition_to!(:interview_scheduled)
    end

    def mark_passed!
      transition_to!(:passed, result: :passed, result_decided_at: Time.current)
    end

    def mark_failed!
      transition_to!(:failed, result: :failed, result_decided_at: Time.current)
    end

    def cancel!
      transition_to!(:canceled, result: :canceled, result_decided_at: Time.current)
    end

    def close!
      transition_to!(:closed, closed_at: Time.current)
    end

    private

    attr_reader :exam_application, :actor

    def transition_to!(next_status, attributes = {})
      next_status = next_status.to_s

      exam_application.with_lock do
        previous_status = exam_application.status
        ensure_transition_allowed!(previous_status, next_status)

        exam_application.update!(attributes.merge(status: next_status))
        StatusChangeRecorder.call(
          exam_application: exam_application,
          actor: actor,
          previous_status: previous_status,
          next_status: next_status
        )
      end

      exam_application
    end

    def ensure_transition_allowed!(previous_status, next_status)
      return if ALLOWED_TRANSITIONS.fetch(previous_status).include?(next_status)

      raise InvalidTransitionError, "cannot transition exam application from #{previous_status} to #{next_status}"
    end
  end
end
