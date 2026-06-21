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
  belongs_to :secondary_assigned_examiner_profile, class_name: "ExaminerProfile", optional: true
  belongs_to :assignment_overridden_by, class_name: "User", optional: true
  has_many :interview_schedules, dependent: :restrict_with_error
  has_one :interview_result, dependent: :restrict_with_error
  has_many :status_change_events, as: :subject
  has_many :audit_logs, as: :auditable

  validates :requested_at, presence: true
  validates :exam_application_id, uniqueness: { conditions: -> { where(deleted_at: nil) } }
  validate :exam_application_accepts_interview, on: :create
  validate :assigned_examiners_are_distinct
  validate :assigned_examiners_can_evaluate_target
  validate :assigned_examiners_are_not_candidate
  validate :assigned_examiners_have_monthly_capacity

  before_restore :prevent_restore_duplicate

  scope :recent, -> { order(created_at: :desc, id: :desc) }

  def display_name
    "面談応募 / #{exam_application.display_name}"
  end

  def assigned_examiner_name
    assigned_examiner_profiles.map(&:display_name).presence&.join(" / ") || "面接官未定"
  end

  def assigned_examiner_profiles
    [ assigned_examiner_profile, secondary_assigned_examiner_profile ].compact
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
    (scheduled? || calendar_created?) && persisted_interview_result.blank?
  end

  def persisted_interview_result
    result = interview_result
    return result if result&.persisted?
  end

  private

  def exam_application_accepts_interview
    return if exam_application&.review_approved?

    errors.add(:exam_application, :must_be_review_approved)
  end

  def assigned_examiners_are_distinct
    return if assigned_examiner_profile_id.blank? || secondary_assigned_examiner_profile_id.blank?
    return unless assigned_examiner_profile_id == secondary_assigned_examiner_profile_id

    errors.add(:secondary_assigned_examiner_profile, :must_be_different_from_primary_examiner)
  end

  def assigned_examiners_can_evaluate_target
    assigned_examiner_pairs.each do |attribute, profile|
      next if profile.blank?
      next if profile.can_interview_for?(exam_application&.evaluation_target)

      errors.add(attribute, :must_be_able_to_interview_target)
    end
  end

  def assigned_examiners_are_not_candidate
    assigned_examiner_pairs.each do |attribute, profile|
      next unless assigned_examiner_changed_for_validation?(attribute)
      next if profile.blank?
      next unless profile.user_id == exam_application&.candidate_id

      errors.add(attribute, :must_not_be_candidate)
    end
  end

  def assigned_examiners_have_monthly_capacity
    assigned_examiner_pairs.each do |attribute, profile|
      next unless assigned_examiner_changed_for_validation?(attribute)
      next if profile.blank?
      next unless profile.monthly_interview_limit_reached?

      errors.add(attribute, :monthly_interview_limit_reached)
    end
  end

  def assigned_examiner_pairs
    [
      [ :assigned_examiner_profile, assigned_examiner_profile ],
      [ :secondary_assigned_examiner_profile, secondary_assigned_examiner_profile ]
    ]
  end

  def assigned_examiner_changed_for_validation?(attribute)
    return true if new_record?

    public_send("will_save_change_to_#{attribute}_id?")
  end
end
