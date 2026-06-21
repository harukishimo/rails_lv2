module ReviewApplications
  class StatusChangeRecorder
    def self.call(review_application:, actor:, previous_status:, next_status:)
      new(
        review_application: review_application,
        actor: actor,
        previous_status: previous_status,
        next_status: next_status
      ).call
    end

    def initialize(review_application:, actor:, previous_status:, next_status:)
      @review_application = review_application
      @actor = actor
      @previous_status = previous_status
      @next_status = next_status
    end

    def call
      return unless defined?(StatusChangeEvents::RecordService)

      StatusChangeEvents::RecordService.call(
        subject: review_application,
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

    attr_reader :review_application, :actor, :previous_status, :next_status

    def event_type
      "review_application_#{next_status}"
    end

    def message
      "Review application status changed from #{previous_status || 'new'} to #{next_status}"
    end

    def target_path
      "/review_applications/#{review_application.id}"
    end

    def metadata
      exam_application = review_application.exam_application

      {
        review_application_id: review_application.id,
        exam_application_id: exam_application.id,
        evaluation_period_id: exam_application.evaluation_period_id,
        evaluation_target_id: exam_application.evaluation_target_id,
        candidate_id: exam_application.candidate_id,
        sequence_number: review_application.sequence_number
      }
    end
  end
end
