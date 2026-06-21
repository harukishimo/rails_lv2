class InterviewApplication < ApplicationRecord
  acts_as_paranoid
  include RestoreDuplicateGuard

  prevents_restore_duplicates_by :exam_application_id

  enum :status, {
    requested: 0,
    examiner_assigned: 1,
    schedule_requested: 2,
    scheduled: 3,
    calendar_created: 4,
    completed: 5
  }, default: :requested, validate: true

  belongs_to :exam_application
  belongs_to :assigned_examiner_profile, class_name: "ExaminerProfile", optional: true
  belongs_to :assignment_overridden_by, class_name: "User", optional: true
  has_many :interview_schedules, dependent: :restrict_with_error
  has_one :interview_result, dependent: :restrict_with_error
  has_many :status_change_events, as: :subject

  validates :requested_at, presence: true
  validates :exam_application_id, uniqueness: { conditions: -> { where(deleted_at: nil) } }
  validate :exam_application_accepts_interview, on: :create
  validate :assigned_examiner_can_evaluate_target
  validate :assigned_examiner_is_not_candidate
  validate :assigned_examiner_has_monthly_capacity

  before_restore :prevent_restore_duplicate

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def display_name
    "Interview for #{exam_application.display_name}"
  end

  def assigned_examiner_name
    assigned_examiner_profile&.display_name || "面接官未定"
  end

  def schedulable?
    examiner_assigned? || schedule_requested?
  end

  def assignable?
    requested? || examiner_assigned? || schedule_requested?
  end

  def cancelable?
    false
  end

  def closed_for_business?
    completed?
  end

  def result_decidable?
    (scheduled? || calendar_created?) && interview_result.blank?
  end

  private

  def exam_application_accepts_interview
    return if exam_application&.review_approved?

    errors.add(:exam_application, "must be review approved")
  end

  def assigned_examiner_can_evaluate_target
    return if assigned_examiner_profile.blank?
    return if assigned_examiner_profile.can_interview_for?(exam_application&.evaluation_target)

    errors.add(:assigned_examiner_profile, "must be able to evaluate target")
  end

  def assigned_examiner_is_not_candidate
    return unless assigned_examiner_profile_changed_for_validation?
    return if assigned_examiner_profile.blank?
    return unless assigned_examiner_profile.user_id == exam_application&.candidate_id

    errors.add(:assigned_examiner_profile, "must not be the candidate")
  end

  def assigned_examiner_has_monthly_capacity
    return unless assigned_examiner_profile_changed_for_validation?
    return if assigned_examiner_profile.blank?
    return unless assigned_examiner_profile.monthly_interview_limit_reached?

    errors.add(:assigned_examiner_profile, "has reached monthly interview limit")
  end

  def assigned_examiner_profile_changed_for_validation?
    new_record? || will_save_change_to_assigned_examiner_profile_id?
  end
end
