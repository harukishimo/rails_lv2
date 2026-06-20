module ExamApplications
  class StatusChangeRecorder
    def self.call(exam_application:, actor:, previous_status:, next_status:)
      new(
        exam_application: exam_application,
        actor: actor,
        previous_status: previous_status,
        next_status: next_status
      ).call
    end

    def initialize(exam_application:, actor:, previous_status:, next_status:)
      @exam_application = exam_application
      @actor = actor
      @previous_status = previous_status
      @next_status = next_status
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
        metadata: metadata
      )
    end

    private

    attr_reader :exam_application, :actor, :previous_status, :next_status

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
