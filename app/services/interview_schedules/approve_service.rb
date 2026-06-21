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
          InterviewApplications::TransitionService.new(
            interview_application,
            actor: actor,
            deliver_to_slack: false
          ).approve_schedule!
          transition_exam_application_to_interview_scheduled
          interview_schedule
        end
      end
      record_interview_confirmed_event(approved_schedule)
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

      ExamApplications::TransitionService.new(
        exam_application,
        actor: actor,
        deliver_to_slack: false
      ).schedule_interview!
    end

    def record_interview_confirmed_event(approved_schedule)
      return unless defined?(StatusChangeEvents::RecordService)

      metadata = interview_confirmed_metadata(approved_schedule)
      StatusChangeEvents::RecordService.call(
        subject: interview_application,
        actor: actor,
        from_status: nil,
        to_status: "interview_confirmed",
        event_type: "interview_confirmed",
        message: interview_confirmed_message(metadata),
        target_path: "/interview_applications/#{interview_application.id}",
        metadata: metadata,
        deliver_to_slack: true
      )
    end

    def interview_confirmed_metadata(approved_schedule)
      application = approved_schedule.interview_application
      exam_application = application.exam_application
      evaluation_target = exam_application.evaluation_target
      examiner_names = application.assigned_examiner_profiles.map(&:display_name)

      {
        exam_application_id: exam_application.id,
        interview_schedule_id: approved_schedule.id,
        evaluation_period_id: exam_application.evaluation_period_id,
        evaluation_target_id: exam_application.evaluation_target_id,
        candidate_id: exam_application.candidate_id,
        candidate_name: exam_application.candidate.name,
        skill_name: evaluation_target.framework&.name.presence || evaluation_target.programming_language.name,
        skill_level: evaluation_target.skill_level.numeric_level || evaluation_target.skill_level.code,
        examiner_names: examiner_names,
        starts_at: approved_schedule.starts_at&.iso8601,
        ends_at: approved_schedule.ends_at&.iso8601,
        timezone: approved_schedule.timezone
      }
    end

    def interview_confirmed_message(metadata)
      [
        "面談が確定しました！",
        "受験者：#{metadata.fetch(:candidate_name)}",
        "言語：#{metadata.fetch(:skill_name)}",
        "lv : #{metadata.fetch(:skill_level)}",
        "試験官: #{metadata.fetch(:examiner_names).join('、')}"
      ].join("\n")
    end
  end
end
