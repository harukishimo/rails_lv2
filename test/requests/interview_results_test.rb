require "test_helper"

class InterviewResultsTest < ActionDispatch::IntegrationTest
  test "assigned examiner sees result form when interview schedule is approved" do
    interview_application, examiner = create_scheduled_interview_application
    sign_in_as(examiner)

    get interview_application_path(interview_application)

    assert_response :success
    assert interview_application.reload.scheduled?
    assert_includes response.body, "面談結果を登録"
    assert_includes response.body, "判定"
  end

  test "assigned examiner can register passed interview result" do
    interview_application, examiner = create_scheduled_interview_application
    sign_in_as(examiner)

    assert_difference -> { InterviewResult.count }, 1 do
      assert_difference -> { UserQualification.count }, 1 do
        post interview_application_interview_result_path(interview_application), params: {
          interview_result: {
            result: "passed",
            comment_markdown: "passed"
          }
        }
      end
    end

    assert_redirected_to interview_application_path(interview_application)
    assert interview_application.reload.completed?
    assert interview_application.exam_application.reload.closed?
    assert interview_application.exam_application.result_passed?

    follow_redirect!
    assert_response :success
    assert_includes response.body, "面談結果"
    assert_includes response.body, "合格"
    assert_includes response.body, "passed"
    assert_not_includes response.body, "面談結果はまだ登録されていません。"

    qualification = UserQualification.find_by!(
      user: interview_application.exam_application.candidate,
      evaluation_target: interview_application.exam_application.evaluation_target
    )
    sign_in_as(interview_application.exam_application.candidate)
    get user_qualifications_path

    assert_response :success
    assert_includes response.body, qualification.user.name
    assert_includes response.body, qualification.evaluation_target.programming_language.name
    assert_includes response.body, qualification.evaluation_target.skill_level.code
  end

  test "secondary assigned examiner can register passed interview result" do
    interview_application, _primary_examiner, secondary_examiner = create_scheduled_interview_application(with_secondary: true)
    sign_in_as(secondary_examiner)

    assert_difference -> { InterviewResult.count }, 1 do
      assert_difference -> { UserQualification.count }, 1 do
        post interview_application_interview_result_path(interview_application), params: {
          interview_result: {
            result: "passed",
            comment_markdown: "passed by secondary examiner"
          }
        }
      end
    end

    assert_redirected_to interview_application_path(interview_application)
    assert interview_application.reload.completed?
    assert interview_application.exam_application.reload.closed?
    assert interview_application.exam_application.result_passed?
  end

  test "assigned examiner can register failed result without qualification" do
    interview_application, examiner = create_scheduled_interview_application
    sign_in_as(examiner)

    assert_difference -> { InterviewResult.count }, 1 do
      assert_no_difference -> { UserQualification.count } do
        post interview_application_interview_result_path(interview_application), params: {
          interview_result: {
            result: "failed",
            comment_markdown: "failed"
          }
        }
      end
    end

    assert_redirected_to interview_application_path(interview_application)
    assert interview_application.reload.completed?
    assert interview_application.exam_application.reload.closed?
    assert interview_application.exam_application.result_failed?
  end

  test "candidate cannot register interview result" do
    interview_application, = create_scheduled_interview_application
    candidate = interview_application.exam_application.candidate
    sign_in_as(candidate)

    post interview_application_interview_result_path(interview_application), params: {
      interview_result: {
        result: "passed"
      }
    }

    assert_response :forbidden
    assert_equal 0, InterviewResult.where(interview_application: interview_application).count
  end

  test "unassigned capable examiner cannot register interview result" do
    interview_application, = create_scheduled_interview_application
    other_examiner = create_examiner_for(interview_application.exam_application.evaluation_target)
    sign_in_as(other_examiner)

    post interview_application_interview_result_path(interview_application), params: {
      interview_result: {
        result: "passed"
      }
    }

    assert_response :forbidden
    assert_equal 0, InterviewResult.where(interview_application: interview_application).count
  end

  test "admin can register interview result for another candidate" do
    interview_application, = create_scheduled_interview_application
    admin = create_user_with_role(Role::ADMIN)
    sign_in_as(admin)

    assert_difference -> { InterviewResult.count }, 1 do
      post interview_application_interview_result_path(interview_application), params: {
        interview_result: {
          result: "passed"
        }
      }
    end

    assert_redirected_to interview_application_path(interview_application)
    assert interview_application.reload.completed?
  end

  test "admin candidate cannot register own interview result" do
    interview_application, = create_scheduled_interview_application
    candidate = interview_application.exam_application.candidate
    add_role(candidate, Role::ADMIN)
    sign_in_as(candidate)

    post interview_application_interview_result_path(interview_application), params: {
      interview_result: {
        result: "passed"
      }
    }

    assert_response :forbidden
    assert_equal 0, InterviewResult.where(interview_application: interview_application).count
  end

  test "missing result returns validation error" do
    interview_application, examiner = create_scheduled_interview_application
    sign_in_as(examiner)

    post interview_application_interview_result_path(interview_application), params: {
      interview_result: {
        comment_markdown: "no result"
      }
    }

    assert_response :unprocessable_entity
    assert_equal 0, InterviewResult.where(interview_application: interview_application).count
  end

  test "assigned examiner cannot register duplicate interview result" do
    interview_application, examiner = create_scheduled_interview_application
    QualificationGrantService.call(
      interview_application: interview_application,
      examiner: examiner,
      attributes: { result: "failed" }
    )
    sign_in_as(examiner)

    post interview_application_interview_result_path(interview_application), params: {
      interview_result: {
        result: "failed"
      }
    }

    assert_response :forbidden
    assert_equal 1, InterviewResult.where(interview_application: interview_application).count
  end

  private

  def create_scheduled_interview_application(with_secondary: false)
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
    secondary_examiner = create_examiner_for(exam_application.evaluation_target) if with_secondary
    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: examiner,
      examiner_profile: examiner.examiner_profile,
      secondary_examiner_profile: secondary_examiner&.examiner_profile
    )
    starts_at = future_quarter_hour(days: 1)
    schedule = InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: candidate,
      attributes: {
        starts_at: starts_at,
        ends_at: starts_at + 30.minutes
      }
    )
    InterviewSchedules::ApproveService.call(interview_schedule: schedule, actor: examiner)

    [ interview_application.reload, examiner, secondary_examiner ]
  end

  def future_quarter_hour(days:, hour: 10, min: 0)
    Time.zone.local(Date.current.year, Date.current.month, Date.current.day, hour, min, 0) + days.days
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

  def add_role(user, code)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    UserRole.create!(user: user, role: role)
  end

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
