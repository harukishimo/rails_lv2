require "test_helper"

class EvaluationLifecycleTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "candidate review interview and qualification lifecycle completes with persisted evidence" do
    candidate = create_user_with_role(Role::CANDIDATE, name: "Lifecycle Candidate")
    target = create_evaluation_target
    examiner = create_examiner_for(target)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: target,
      actor: candidate
    )

    review_application = ReviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate,
      attributes: {
        appeal_markdown: "Lifecycle review evidence",
        submissions_attributes: [
          {
            kind: "github_repository",
            title: "Repository",
            github_url: "https://github.com/harukishimo/rails_lv2"
          }
        ]
      }
    )
    ReviewDecisions::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { decision: "approve", reason_markdown: "Looks good" }
    )

    assert review_application.reload.approved?
    assert exam_application.reload.review_approved?

    interview_application = InterviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate
    )
    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: examiner,
      examiner_profile: examiner.examiner_profile
    )
    starts_at = future_quarter_hour(days: 2)
    schedule = InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: candidate,
      attributes: {
        starts_at: starts_at,
        ends_at: starts_at + 30.minutes
      }
    )

    assert_no_enqueued_jobs only: CalendarEventCreateJob do
      assert_enqueued_with(job: SlackDeliveryJob) do
        InterviewSchedules::ApproveService.call(interview_schedule: schedule, actor: examiner)
      end
    end
    perform_enqueued_jobs

    assert schedule.reload.approved?
    assert interview_application.reload.scheduled?

    result = QualificationGrantService.call(
      interview_application: interview_application,
      examiner: examiner,
      attributes: { result: "passed", comment_markdown: "Passed" }
    )

    assert result.passed?
    assert interview_application.reload.completed?
    assert exam_application.reload.closed?
    qualification = UserQualification.active.find_by!(
      user: candidate,
      evaluation_target: target,
      exam_application: exam_application
    )
    assert_equal examiner, qualification.granted_by
    assert StatusChangeEvent.where(subject: review_application).exists?(to_status: "approved")
    assert StatusChangeEvent.where(subject: interview_application).exists?(event_type: "interview_confirmed")
  end

  private

  def future_quarter_hour(days:, hour: 10, min: 0)
    Time.zone.local(Date.current.year, Date.current.month, Date.current.day, hour, min, 0) + days.days
  end

  def create_evaluation_period
    EvaluationPeriod.create!(
      name: "Period #{SecureRandom.hex(4)}",
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year
    )
  end

  def create_evaluation_target
    language = ProgrammingLanguage.create!(name: "Ruby #{SecureRandom.hex(4)}")
    framework = Framework.create!(name: "Rails #{SecureRandom.hex(4)}", programming_language: language)

    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv2-#{SecureRandom.hex(4)}", numeric_level: 2),
      external_knowledge_key: "ruby_lv2_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}"
    )
  end

  def create_examiner_for(target)
    examiner = create_user_with_role(Role::EXAMINER, name: "Lifecycle Examiner")
    profile = ExaminerProfile.create!(
      user: examiner,
      display_name: "Examiner #{SecureRandom.hex(4)}"
    )
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: target,
      can_review: true,
      can_interview: true
    )
    examiner
  end

  def create_user_with_role(code, name:)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    user = User.create!(
      name: name,
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    user
  end
end
