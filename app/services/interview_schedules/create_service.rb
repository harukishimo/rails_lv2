module InterviewSchedules
  class CreateService
    def self.call(interview_application:, actor:, attributes:)
      new(interview_application: interview_application, actor: actor, attributes: attributes).call
    end

    def initialize(interview_application:, actor:, attributes:)
      @interview_application = interview_application
      @actor = actor
      @attributes = attributes
    end

    def call
      InterviewSchedule.transaction do
        interview_application.with_lock do
          raise_not_schedulable! unless interview_application.schedulable?

          schedule = interview_application.interview_schedules.create!(
            schedule_attributes.merge(status: :requested)
          )
          InterviewApplications::TransitionService.new(interview_application, actor: actor).request_schedule!
          schedule
        end
      end
    end

    private

    attr_reader :interview_application, :actor, :attributes

    def schedule_attributes
      attributes.slice(:starts_at, :ends_at, :timezone)
    end

    def raise_not_schedulable!
      interview_application.errors.add(:base, :interview_application_does_not_accept_schedules)
      raise ActiveRecord::RecordInvalid, interview_application
    end
  end
end
