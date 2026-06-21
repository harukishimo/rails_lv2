module InterviewSchedules
  class RejectService
    def self.call(interview_schedule:, actor:)
      new(interview_schedule: interview_schedule, actor: actor).call
    end

    def initialize(interview_schedule:, actor:)
      @interview_schedule = interview_schedule
      @actor = actor
    end

    def call
      InterviewSchedule.transaction do
        interview_application.with_lock do
          interview_schedule.lock!
          raise_not_rejectable! unless interview_schedule.rejectable?

          interview_schedule.update!(status: :rejected)
          interview_schedule
        end
      end
    end

    private

    attr_reader :interview_schedule, :actor

    def interview_application
      @interview_application ||= interview_schedule.interview_application
    end

    def raise_not_rejectable!
      interview_schedule.errors.add(:base, :interview_schedule_not_rejectable)
      raise ActiveRecord::RecordInvalid, interview_schedule
    end
  end
end
