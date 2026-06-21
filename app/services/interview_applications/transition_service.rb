module InterviewApplications
  class TransitionService
    class InvalidTransitionError < StandardError; end

    ALLOWED_TRANSITIONS = {
      "requested" => %w[examiner_assigned schedule_requested],
      "examiner_assigned" => %w[schedule_requested],
      "schedule_requested" => %w[scheduled],
      "scheduled" => %w[calendar_created completed],
      "calendar_created" => %w[completed],
      "completed" => []
    }.freeze

    def initialize(interview_application, actor:, deliver_to_slack: false)
      @interview_application = interview_application
      @actor = actor
      @deliver_to_slack = deliver_to_slack
    end

    def request_schedule!
      transition_to!(:schedule_requested)
    end

    def approve_schedule!
      transition_to!(:scheduled)
    end

    def create_calendar!
      transition_to!(:calendar_created)
    end

    def complete!
      transition_to!(:completed)
    end

    private

    attr_reader :interview_application, :actor, :deliver_to_slack

    def transition_to!(next_status)
      next_status = next_status.to_s
      previous_status = interview_application.status
      return interview_application if previous_status == next_status

      ensure_transition_allowed!(previous_status, next_status)
      interview_application.update!(status: next_status)
      StatusChangeRecorder.call(
        interview_application: interview_application,
        actor: actor,
        previous_status: previous_status,
        next_status: next_status,
        deliver_to_slack: deliver_to_slack
      )
      interview_application
    end

    def ensure_transition_allowed!(previous_status, next_status)
      return if ALLOWED_TRANSITIONS.fetch(previous_status).include?(next_status)

      raise InvalidTransitionError, "cannot transition interview application from #{previous_status} to #{next_status}"
    end
  end
end
