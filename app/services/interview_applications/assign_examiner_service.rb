module InterviewApplications
  class AssignExaminerService
    def self.call(interview_application:, actor:, examiner_profile:, secondary_examiner_profile: nil, reason: nil)
      new(
        interview_application: interview_application,
        actor: actor,
        examiner_profile: examiner_profile,
        secondary_examiner_profile: secondary_examiner_profile,
        reason: reason
      ).call
    end

    def initialize(interview_application:, actor:, examiner_profile:, secondary_examiner_profile: nil, reason: nil)
      @interview_application = interview_application
      @actor = actor
      @examiner_profile = examiner_profile
      @secondary_examiner_profile = secondary_examiner_profile
      @reason = reason.to_s.strip.presence
    end

    def call
      InterviewApplication.transaction do
        interview_application.with_lock do
          raise_examiner_required! if examiner_profile.blank?
          lock_examiner_profiles!
          raise_not_assignable! unless interview_application.assignable?
          raise_duplicate_examiner! if duplicate_examiner?
          validate_examiner_profile!(examiner_profile, :assigned_examiner_profile)
          validate_examiner_profile!(secondary_examiner_profile, :secondary_assigned_examiner_profile) if secondary_examiner_profile.present?
          raise_reason_required! if manual_override? && reason.blank?

          previous_status = interview_application.status
          previous_profiles = interview_application.assigned_examiner_profiles
          previous_override_actor_id = interview_application.assignment_overridden_by_id
          previous_override_reason_present = interview_application.assignment_override_reason.present?
          assignment_changed = previous_profiles.map(&:id) != examiner_profiles.map(&:id)
          interview_application.update!(assignment_attributes)
          update_monthly_interview_counts(previous_profiles: previous_profiles, new_profiles: examiner_profiles)
          record_status_change(previous_status)
          record_assignment_audit_log(
            previous_profiles: previous_profiles,
            previous_override_actor_id: previous_override_actor_id,
            previous_override_reason_present: previous_override_reason_present
          ) if assignment_changed || manual_override?
          interview_application
        end
      end
    end

    private

    attr_reader :interview_application, :actor, :examiner_profile, :secondary_examiner_profile, :reason

    def assignment_attributes
      {
        assigned_examiner_profile: examiner_profile,
        secondary_assigned_examiner_profile: secondary_examiner_profile,
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
      return false if suggested_profiles.blank?

      suggested_profiles.first(examiner_profiles.size).map(&:id) != examiner_profiles.map(&:id)
    end

    def suggested_profiles
      @suggested_profiles ||= Array.wrap(
        ExaminerSuggestionService.call(interview_application: interview_application, limit: 2)
      )
    end

    def examiner_profiles
      [ examiner_profile, secondary_examiner_profile ].compact
    end

    def lock_examiner_profiles!
      examiner_profiles.sort_by(&:id).each(&:lock!)
    end

    def update_monthly_interview_counts(previous_profiles:, new_profiles:)
      previous_ids = previous_profiles.map(&:id)
      new_ids = new_profiles.map(&:id)

      previous_profiles.each do |profile|
        decrement_monthly_interview_count(profile) if previous_ids.count(profile.id) > new_ids.count(profile.id)
      end
      new_profiles.each do |profile|
        increment_monthly_interview_count(profile) if new_ids.count(profile.id) > previous_ids.count(profile.id)
      end
    end

    def decrement_monthly_interview_count(profile)
      return if profile.monthly_interview_count.zero?

      profile.update!(monthly_interview_count: profile.monthly_interview_count - 1)
    end

    def increment_monthly_interview_count(profile)
      profile.update!(monthly_interview_count: profile.monthly_interview_count + 1)
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

    def record_assignment_audit_log(previous_profiles:, previous_override_actor_id:, previous_override_reason_present:)
      return unless defined?(AuditLogs::RecordService)

      AuditLogs::RecordService.call(
        action: "interview_application.examiner_assigned",
        actor: actor,
        auditable: interview_application,
        before_changes: {
          assigned_examiner_profile_id: previous_profiles.first&.id,
          secondary_assigned_examiner_profile_id: previous_profiles.second&.id,
          assignment_overridden_by_id: previous_override_actor_id,
          assignment_override_reason_present: previous_override_reason_present
        },
        after_changes: {
          assigned_examiner_profile_id: interview_application.assigned_examiner_profile_id,
          secondary_assigned_examiner_profile_id: interview_application.secondary_assigned_examiner_profile_id,
          assignment_overridden_by_id: interview_application.assignment_overridden_by_id,
          assignment_override_reason_present: interview_application.assignment_override_reason.present?,
          manual_override: manual_override?
        }
      )
    end

    def duplicate_examiner?
      examiner_profile.present? &&
        secondary_examiner_profile.present? &&
        examiner_profile.id == secondary_examiner_profile.id
    end

    def validate_examiner_profile!(profile, attribute)
      raise_not_capable!(attribute) unless profile.can_interview_for?(interview_application.exam_application.evaluation_target)
      raise_self_assignment!(attribute) if profile.user_id == interview_application.exam_application.candidate_id
      raise_monthly_limit_reached!(attribute) if new_assignment?(profile) && profile.monthly_interview_limit_reached?
    end

    def new_assignment?(profile)
      interview_application.assigned_examiner_profiles.none? { |assigned_profile| assigned_profile.id == profile.id }
    end

    def raise_examiner_required!
      interview_application.errors.add(:assigned_examiner_profile, :must_be_selected)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_not_assignable!
      interview_application.errors.add(:base, :interview_application_not_assignable)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_duplicate_examiner!
      interview_application.errors.add(:secondary_assigned_examiner_profile, :must_be_different_from_primary_examiner)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_not_capable!(attribute)
      interview_application.errors.add(attribute, :must_be_able_to_interview_target)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_self_assignment!(attribute)
      interview_application.errors.add(attribute, :must_not_be_candidate)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_monthly_limit_reached!(attribute)
      interview_application.errors.add(attribute, :monthly_interview_limit_reached)
      raise ActiveRecord::RecordInvalid, interview_application
    end

    def raise_reason_required!
      interview_application.errors.add(:assignment_override_reason, :required_for_manual_override)
      raise ActiveRecord::RecordInvalid, interview_application
    end
  end
end
