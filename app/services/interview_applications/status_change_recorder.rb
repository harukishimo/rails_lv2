module InterviewApplications
  class StatusChangeRecorder
    def self.call(interview_application:, actor:, previous_status:, next_status:, deliver_to_slack: false)
      new(
        interview_application: interview_application,
        actor: actor,
        previous_status: previous_status,
        next_status: next_status,
        deliver_to_slack: deliver_to_slack
      ).call
    end

    def initialize(interview_application:, actor:, previous_status:, next_status:, deliver_to_slack: false)
      @interview_application = interview_application
      @actor = actor
      @previous_status = previous_status
      @next_status = next_status
      @deliver_to_slack = deliver_to_slack
    end

    def call
      return unless defined?(StatusChangeEvents::RecordService)

      StatusChangeEvents::RecordService.call(
        subject: interview_application,
        actor: actor,
        from_status: previous_status,
        to_status: next_status,
        event_type: event_type,
        message: message,
        target_path: target_path,
        metadata: metadata,
        deliver_to_slack: deliver_to_slack
      )
    end

    private

    attr_reader :interview_application, :actor, :previous_status, :next_status, :deliver_to_slack

    def event_type
      "interview_application_#{next_status}"
    end

    def message
      "Interview application status changed from #{previous_status || 'new'} to #{next_status}"
    end

    def target_path
      "/interview_applications/#{interview_application.id}"
    end

    def metadata
      exam_application = interview_application.exam_application

      {
        exam_application_id: exam_application.id,
        evaluation_period_id: exam_application.evaluation_period_id,
        evaluation_target_id: exam_application.evaluation_target_id,
        candidate_id: exam_application.candidate_id
      }
    end
  end
end
