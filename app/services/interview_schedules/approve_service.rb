module InterviewSchedules
  class ApproveService
    def self.call(interview_schedule:, actor:)
      new(interview_schedule: interview_schedule, actor: actor).call
    end

    def initialize(interview_schedule:, actor:)
      @interview_schedule = interview_schedule
      @actor = actor
    end

    def call
      approved_schedule = InterviewSchedule.transaction do
        interview_application.with_lock do
          interview_schedule.lock!
          raise_not_approvable! unless interview_schedule.approvable?

          interview_schedule.update!(status: :approved)
          InterviewApplications::TransitionService.new(interview_application, actor: actor).approve_schedule!
          transition_exam_application_to_interview_scheduled
          interview_schedule
        end
      end
      CalendarEventCreateJob.perform_later(approved_schedule.id, actor_id: actor.id) if defined?(CalendarEventCreateJob)
      approved_schedule
    end

    private

    attr_reader :interview_schedule, :actor

    def interview_application
      @interview_application ||= interview_schedule.interview_application
    end

    def raise_not_approvable!
      interview_schedule.errors.add(:base, :interview_schedule_not_approvable)
      raise ActiveRecord::RecordInvalid, interview_schedule
    end

    def transition_exam_application_to_interview_scheduled
      exam_application = interview_application.exam_application
      return unless exam_application.interview_requested?

      ExamApplications::TransitionService.new(exam_application, actor: actor).schedule_interview!
    end
  end
end
