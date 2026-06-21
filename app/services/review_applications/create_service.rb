module ReviewApplications
  class CreateService
    def self.call(exam_application:, actor:, attributes:)
      new(exam_application: exam_application, actor: actor, attributes: attributes).call
    end

    def initialize(exam_application:, actor:, attributes:)
      @exam_application = exam_application
      @actor = actor
      @attributes = attributes
    end

    def call
      ReviewApplication.transaction do
        exam_application.with_lock do
          review_application = exam_application.review_applications.create!(
            review_attributes.merge(
              sequence_number: next_sequence_number,
              status: :submitted,
              submitted_at: Time.current
            )
          )

          transition_exam_application_to_reviewing
          review_application
        end
      end
    end

    private

    attr_reader :exam_application, :actor, :attributes

    def review_attributes
      attributes.slice(:appeal_markdown, :submissions_attributes)
    end

    def next_sequence_number
      ReviewApplication.with_deleted.where(exam_application: exam_application).maximum(:sequence_number).to_i + 1
    end

    def transition_exam_application_to_reviewing
      return unless exam_application.declared?

      ExamApplications::TransitionService.new(exam_application, actor: actor).start_review!
    end
  end
end
