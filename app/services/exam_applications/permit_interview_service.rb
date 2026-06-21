module ExamApplications
  class PermitInterviewService
    def self.call(exam_application:, actor:)
      new(exam_application: exam_application, actor: actor).call
    end

    def initialize(exam_application:, actor:)
      @exam_application = exam_application
      @actor = actor
    end

    def call
      ExamApplication.transaction do
        raise_not_permittable! unless exam_application.permit_interview?

        TransitionService.new(exam_application, actor: actor).permit_interview!
      end
    end

    private

    attr_reader :exam_application, :actor

    def raise_not_permittable!
      exam_application.errors.add(:base, :exam_application_not_permittable_for_interview)
      raise ActiveRecord::RecordInvalid, exam_application
    end
  end
end
