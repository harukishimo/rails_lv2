class InterviewApplicationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if user.admin?

      visible_scope = scope.none
      visible_scope = visible_scope.or(scope.where(id: candidate_interview_ids)) if user.candidate?
      visible_scope = visible_scope.or(scope.where(id: examiner_interview_ids)) if user.examiner?
      visible_scope
    end

    private

    def candidate_interview_ids
      scope.joins(:exam_application)
           .where(exam_applications: { candidate_id: user.id })
           .select(:id)
    end

    def examiner_interview_ids
      scope.joins(:exam_application)
           .where(exam_applications: { evaluation_target_id: evaluation_target_ids })
           .select(:id)
    end

    def evaluation_target_ids
      user.examiner_profile&.examiner_skill_capabilities&.interviewable&.pluck(:evaluation_target_id) || []
    end
  end

  class QueueScope < Scope
    def resolve
      return scope.all if user.admin?
      return scope.none unless interview_queue_visible?

      scope.joins(:exam_application)
           .where(exam_applications: { evaluation_target_id: evaluation_target_ids })
           .where.not(exam_applications: { candidate_id: user.id })
    end

    private

    def interview_queue_visible?
      user.examiner? && user.examiner_profile&.active? && user.examiner_profile&.can_interview?
    end

    def evaluation_target_ids
      user.examiner_profile&.examiner_skill_capabilities&.interviewable&.pluck(:evaluation_target_id) || []
    end
  end

  def show?
    owner? || user.admin? || examiner_capable?
  end

  def queue?
    user.admin? || (user.examiner? && user.examiner_profile&.active? && user.examiner_profile&.can_interview?)
  end

  def create?
    user.candidate? && record.exam_application.candidate_id == user.id && acceptable_exam_application?
  end

  def new?
    create?
  end

  def schedule?
    (owner? || user.admin?) && record.schedulable?
  end

  def approve_schedule?
    (user.admin? || examiner_capable?) && !self_interview?
  end

  def reject_schedule?
    approve_schedule?
  end

  def assignment?
    assign?
  end

  def assign?
    (user.admin? || examiner_capable?) && record.assignable? && !self_interview?
  end

  def decide_result?
    (user.admin? || assigned_examiner?) && record.result_decidable? && !self_interview?
  end

  def cancel?
    false
  end

  private

  def owner?
    user.candidate? && record.exam_application.candidate_id == user.id
  end

  def self_interview?
    record.exam_application.candidate_id == user.id
  end

  def examiner_capable?
    user.examiner? && user.examiner_profile&.can_interview_for?(record.exam_application.evaluation_target)
  end

  def assigned_examiner?
    user.examiner? && record.assigned_examiner_profiles.any? { |profile| profile.user_id == user.id }
  end

  def acceptable_exam_application?
    return true if InterviewApplication.exists?(exam_application_id: record.exam_application_id)

    record.exam_application.review_approved?
  end
end
