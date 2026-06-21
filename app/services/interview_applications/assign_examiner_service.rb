module InterviewApplications
  class AssignExaminerService
    def self.call(interview_application:, actor:, examiner_profile:, reason: nil)
      new(
        interview_application: interview_application,
        actor: actor,
        examiner_profile: examiner_profile,
        reason: reason
      ).call
    end

    def initialize(interview_application:, actor:, examiner_profile:, reason: nil)
      @interview_application = interview_application
      @actor = actor
      @examiner_profile = examiner_profile
      @reason = reason.to_s.strip.presence
    end

    def call
      InterviewApplication.transaction do
        interview_application.with_lock do
          raise_examiner_required! if examiner_profile.blank?

          examiner_profile.with_lock do
            raise_not_assignable! unless interview_application.assignable?
            raise_not_capable! unless examiner_profile.can_interview_for?(interview_application.exam_application.evaluation_target)
            raise_self_assignment! if self_assignment?
            raise_monthly_limit_reached! if new_assignment? && examiner_profile.monthly_interview_limit_reached?
            raise_reason_required! if manual_override? && reason.blank?

            previous_status = interview_application.status
            previous_profile = interview_application.assigned_examiner_profile
            previous_override_actor_id = interview_application.assignment_overridden_by_id
            previous_override_reason_present = interview_application.assignment_override_reason.present?
            assignment_changed = previous_profile&.id != examiner_profile.id
            interview_application.update!(assignment_attributes)
            update_monthly_interview_counts(previous_profile, assignment_changed: assignment_changed)
            record_status_change(previous_status)
            record_assignment_audit_log(
              previous_profile: previous_profile,
              previous_override_actor_id: previous_override_actor_id,
              previous_override_reason_present: previous_override_reason_present
            ) if assignment_changed || manual_override?
          end
          interview_application
        end
      end
    end

    private

    attr_reader :interview_application, :actor, :examiner_profile, :reason

    def assignment_attributes
      {
        assigned_examiner_profile: examiner_profile,
        status: assigned_status
      }.merge(override_attributes)
    end

    def assigned_status
      return :examiner_assigned if interview_application.requested?

      interview_application.status
    end

    def override_attributes
      return { assignment_overridden_by: nil, assignment_override_reason: nil } unless manual_override?

      {
        assignment_overridden_by: actor,
        assignment_override_reason: reason
      }
    end

    def manual_override?
      suggested_profile.present? && suggested_profile.id != examiner_profile.id
    end

    def suggested_profile
      @suggested_profile ||= ExaminerSuggestionService.call(interview_application: interview_application)
    end

    def update_monthly_interview_counts(previous_profile, assignment_changed:)
      return unless assignment_changed

      decrement_monthly_interview_count(previous_profile) if previous_profile.present?
      examiner_profile.update!(monthly_interview_count: examiner_profile.monthly_interview_count + 1)
    end

    def decrement_monthly_interview_count(profile)
      return if profile.monthly_interview_count.zero?

      profile.with_lock do
        profile.update!(monthly_interview_count: profile.monthly_interview_count - 1)
      end
    end

    def new_assignment?
      interview_application.assigned_examiner_profile_id != examiner_profile.id
    end

    def record_status_change(previous_status)
      next_status = interview_application.status
      return if previous_status == next_status

      StatusChangeRecorder.call(
        interview_application: interview_application,
        actor: actor,
        previous_status: previous_status,
        next_status: next_status
      )
    end

    def record_assignment_audit_log(previous_profile:, previous_override_actor_id:, previous_override_reason_present:)
      return unless defined?(AuditLogs::RecordService)

      AuditLogs::RecordService.call(
        action: "interview_application.examiner_assigned",
        actor: actor,
        auditable: interview_application,
        before_changes: {
          assigned_examiner_profile_id: previous_profile&.id,
          assignment_overridden_by_id: previous_override_actor_id,
          assignment_override_reason_present: previous_override_reason_present
        },
        after_changes: {
          assigned_examiner_profile_id: interview_application.assigned_examiner_profile_id,
          assignment_overridden_by_id: interview_application.assignment_overridden_by_id,
          assignment_override_reason_present: interview_application.assignment_override_reason.present?,
          manual_override: manual_override?
        }
      )
    end

    def self_assignment?
      examiner_profile.user_id == interview_application.exam_application.candidate_id
    end

    def raise_examiner_required!
      interview_application.errors.add(:assigned_examiner_profile, :must_be_selected)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_not_assignable!
      interview_application.errors.add(:base, :interview_application_not_assignable)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_not_capable!
      interview_application.errors.add(:assigned_examiner_profile, :must_be_able_to_interview_target)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_self_assignment!
      interview_application.errors.add(:assigned_examiner_profile, :must_not_be_candidate)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_monthly_limit_reached!
      interview_application.errors.add(:assigned_examiner_profile, :monthly_interview_limit_reached)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_reason_required!
      interview_application.errors.add(:assignment_override_reason, :required_for_manual_override)
      raise ActiveRecord::RecordInvalid, interview_application
    end
  end
end
