module ExamApplications
  class StatusChangeRecorder
    def self.call(exam_application:, actor:, previous_status:, next_status:, deliver_to_slack: false)
      new(
        exam_application: exam_application,
        actor: actor,
        previous_status: previous_status,
        next_status: next_status,
        deliver_to_slack: deliver_to_slack
      ).call
    end

    def initialize(exam_application:, actor:, previous_status:, next_status:, deliver_to_slack: false)
      @exam_application = exam_application
      @actor = actor
      @previous_status = previous_status
      @next_status = next_status
      @deliver_to_slack = deliver_to_slack
    end

    def call
      return unless defined?(StatusChangeEvents::RecordService)

      StatusChangeEvents::RecordService.call(
        subject: exam_application,
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

    attr_reader :exam_application, :actor, :previous_status, :next_status, :deliver_to_slack

    def event_type
      "exam_application_#{next_status}"
    end

    def message
      "Exam application status changed from #{previous_status} to #{next_status}"
    end

    def target_path
      "/exam_applications/#{exam_application.id}"
    end

    def metadata
      {
        evaluation_period_id: exam_application.evaluation_period_id,
        evaluation_target_id: exam_application.evaluation_target_id,
        candidate_id: exam_application.candidate_id
      }
    end
  end
end
