module InterviewApplications
  class CreateService
    def self.call(exam_application:, actor:)
      new(exam_application: exam_application, actor: actor).call
    end

    def initialize(exam_application:, actor:)
      @exam_application = exam_application
      @actor = actor
    end

    def call
      InterviewApplication.transaction do
        exam_application.with_lock do
          interview_application = InterviewApplication.create!(
            exam_application: exam_application,
            status: :requested,
            requested_at: Time.current
          )
          transition_exam_application_to_interview_requested
          record_status_change!(interview_application)
          interview_application
        end
      end
    end

    private

    attr_reader :exam_application, :actor

    def transition_exam_application_to_interview_requested
      ExamApplications::TransitionService.new(exam_application, actor: actor).request_interview!
    end

    def record_status_change!(interview_application)
      StatusChangeRecorder.call(
        interview_application: interview_application,
        actor: actor,
        previous_status: nil,
        next_status: interview_application.status
      )
    end
  end
end
