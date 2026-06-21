require "test_helper"

class QualificationGrantServiceTest < ActiveSupport::TestCase
  test "passing result creates qualification and closes exam application atomically" do
    interview_application, examiner = create_calendar_created_interview_application
    exam_application = interview_application.exam_application

    assert_difference -> { InterviewResult.count }, 1 do
      assert_difference -> { UserQualification.count }, 1 do
        assert_difference -> { StatusChangeEvent.count }, 3 do
          QualificationGrantService.call(
            interview_application: interview_application,
            examiner: examiner,
            attributes: { result: "passed", comment_markdown: "passed **ok**" }
          )
        end
      end
    end

    result = InterviewResult.last
    qualification = UserQualification.last
    assert result.passed?
    assert_includes result.rendered_comment_html, "<strong>ok</strong>"
    assert interview_application.reload.completed?
    assert exam_application.reload.closed?
    assert exam_application.result_passed?
    assert_equal exam_application.candidate, qualification.user
    assert_equal exam_application.evaluation_target, qualification.evaluation_target
    assert_equal exam_application, qualification.exam_application
    assert_equal examiner, qualification.granted_by

    exam_events = StatusChangeEvent.where(subject: exam_application).order(:id)
    interview_events = StatusChangeEvent.where(subject: interview_application).order(:id)
    assert_equal %w[exam_application_passed exam_application_closed], exam_events.last(2).map(&:event_type)
    assert_equal "interview_application_completed", interview_events.last.event_type
    assert_equal "calendar_created", interview_events.last.from_status
    assert_equal "completed", interview_events.last.to_status
  end

  test "failing result closes exam without qualification and allows new attempt" do
    interview_application, examiner = create_calendar_created_interview_application
    exam_application = interview_application.exam_application

    assert_difference -> { InterviewResult.count }, 1 do
      assert_no_difference -> { UserQualification.count } do
        QualificationGrantService.call(
          interview_application: interview_application,
          examiner: examiner,
          attributes: { result: "failed", comment_markdown: "retry" }
        )
      end
    end

    assert interview_application.reload.completed?
    assert exam_application.reload.closed?
    assert exam_application.result_failed?

    next_application = ExamApplications::CreateService.call(
      candidate: exam_application.candidate,
      evaluation_period: exam_application.evaluation_period,
      evaluation_target: exam_application.evaluation_target,
      actor: exam_application.candidate
    )
    assert_equal 2, next_application.attempt_number
    assert next_application.declared?
  end

  test "does not create duplicate qualification for same user and target" do
    interview_application, examiner = create_calendar_created_interview_application
    exam_application = interview_application.exam_application
    previous_application = create_closed_exam_application(
      candidate: exam_application.candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: exam_application.evaluation_target,
      actor: examiner
    )
    existing_qualification = UserQualification.create!(
      user: exam_application.candidate,
      evaluation_target: exam_application.evaluation_target,
      exam_application: previous_application,
      acquired_on: Date.yesterday,
      granted_by: examiner
    )

    assert_no_difference -> { UserQualification.count } do
      QualificationGrantService.call(
        interview_application: interview_application,
        examiner: examiner,
        attributes: { result: "passed" }
      )
    end

    assert_equal exam_application, existing_qualification.reload.exam_application
    assert_equal Date.current, existing_qualification.acquired_on
  end

  test "rejects duplicate interview result" do
    interview_application, examiner = create_calendar_created_interview_application
    QualificationGrantService.call(
      interview_application: interview_application,
      examiner: examiner,
      attributes: { result: "failed" }
    )

    error = assert_raises(ActiveRecord::RecordInvalid) do
      QualificationGrantService.call(
        interview_application: interview_application,
        examiner: examiner,
        attributes: { result: "failed" }
      )
    end

    assert_includes error.record.errors[:base], "interview application does not accept result"
    assert_equal 1, InterviewResult.where(interview_application: interview_application).count
  end

  test "invalid result is returned as record validation error" do
    interview_application, examiner = create_calendar_created_interview_application

    error = assert_raises(ActiveRecord::RecordInvalid) do
      QualificationGrantService.call(
        interview_application: interview_application,
        examiner: examiner,
        attributes: { comment_markdown: "missing result" }
      )
    end

    assert_includes error.record.errors[:result], "can't be blank"
    assert_equal 0, InterviewResult.where(interview_application: interview_application).count
  end

  test "interview result comment html is sanitized" do
    interview_application, examiner = create_calendar_created_interview_application

    result = QualificationGrantService.call(
      interview_application: interview_application,
      examiner: examiner,
      attributes: {
        result: "failed",
        comment_markdown: "[bad](javascript:alert(1))<script>alert(2)</script>"
      }
    )

    assert_no_match(/javascript:/i, result.rendered_comment_html)
    assert_no_match(/<script/i, result.rendered_comment_html)
  end

  test "rolls back result qualification and exam close when later transaction step fails" do
    interview_application, examiner = create_calendar_created_interview_application
    exam_application = interview_application.exam_application
    service = QualificationGrantService.new(
      interview_application: interview_application,
      examiner: examiner,
      attributes: { result: "passed" }
    )
    service.define_singleton_method(:complete_interview!) do
      raise QualificationGrantService::QualificationGrantError, "boom"
    end

    assert_no_difference -> { StatusChangeEvent.count } do
      assert_raises(QualificationGrantService::QualificationGrantError) do
        service.call
      end
    end

    assert_equal 0, InterviewResult.where(interview_application: interview_application).count
    assert_equal 0, UserQualification.where(exam_application: exam_application).count
    assert exam_application.reload.interview_scheduled?
    assert exam_application.result_none?
    assert interview_application.reload.calendar_created?
  end

  private

  def create_calendar_created_interview_application
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
    exam_application.update!(status: :review_approved)
    interview_application = InterviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate
    )
    examiner = create_examiner_for(exam_application.evaluation_target)
    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: examiner,
      examiner_profile: examiner.examiner_profile
    )
    schedule = InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: candidate,
      attributes: {
        starts_at: 1.day.from_now,
        ends_at: 1.day.from_now + 30.minutes
      }
    )
    InterviewSchedules::ApproveService.call(interview_schedule: schedule, actor: examiner)
    CalendarEventCreateJob.perform_now(schedule.id, actor_id: examiner.id)

    [ interview_application.reload, examiner ]
  end

  def create_closed_exam_application(candidate:, evaluation_period:, evaluation_target:, actor:)
    application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: evaluation_period,
      evaluation_target: evaluation_target,
      actor: actor
    )
    application.update!(status: :closed, result: :passed, closed_at: Time.current, result_decided_at: Time.current)
    application
  end

  def create_examiner_for(evaluation_target)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: evaluation_target)
    examiner
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
    framework = Framework.create!(name: "Ruby on Rails #{SecureRandom.hex(4)}", programming_language: language)

    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv#{rand(1000..9999)}", numeric_level: 2),
      external_knowledge_key: "ruby_on_rails_lv2_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}"
    )
  end

  def create_user_with_role(code)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    user = User.create!(
      name: "User",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    user
  end
end
