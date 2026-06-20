require "test_helper"

class InterviewAssignmentsTest < ActionDispatch::IntegrationTest
  test "capable examiner can open assignment form with suggested examiner without saving suggestion" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    suggested = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 3)
    sign_in_as(suggested)

    get assignment_interview_application_path(interview_application)

    assert_response :success
    assert_includes response.body, "suggested_examiner_id=#{suggested.examiner_profile.id}"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  test "capable examiner can confirm suggested examiner" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    sign_in_as(examiner)

    patch assignment_interview_application_path(interview_application), params: {
      interview_application: {
        assigned_examiner_profile_id: examiner.examiner_profile.id
      }
    }

    assert_redirected_to interview_application_path(interview_application)
    interview_application.reload
    assert interview_application.examiner_assigned?
    assert_equal examiner.examiner_profile, interview_application.assigned_examiner_profile
    assert_nil interview_application.assignment_overridden_by
    assert_equal 1, examiner.examiner_profile.reload.monthly_interview_count
  end

  test "capable examiner can manually override suggested examiner with reason" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    suggested = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    override = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 2)
    sign_in_as(suggested)

    patch assignment_interview_application_path(interview_application), params: {
      interview_application: {
        assigned_examiner_profile_id: override.examiner_profile.id,
        assignment_override_reason: "timezone coverage"
      }
    }

    assert_redirected_to interview_application_path(interview_application)
    interview_application.reload
    assert_equal override.examiner_profile, interview_application.assigned_examiner_profile
    assert_equal suggested, interview_application.assignment_overridden_by
    assert_equal "timezone coverage", interview_application.assignment_override_reason
  end

  test "manual override without reason is rejected" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    suggested = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    override = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 2)
    sign_in_as(suggested)

    patch assignment_interview_application_path(interview_application), params: {
      interview_application: {
        assigned_examiner_profile_id: override.examiner_profile.id
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Assignment override reason is required for manual override"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  test "assignment without examiner selection is rejected" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    sign_in_as(examiner)

    patch assignment_interview_application_path(interview_application), params: {
      interview_application: {
        assigned_examiner_profile_id: ""
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "入力内容を確認してください"
    assert_includes response.body, "Assigned examiner profile must be selected"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  test "candidate cannot open assignment form" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    sign_in_as(candidate)

    get assignment_interview_application_path(interview_application)

    assert_response :forbidden
  end

  test "incapable examiner cannot open assignment form" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    examiner = create_examiner_for(create_evaluation_target, monthly_interview_count: 0)
    sign_in_as(examiner)

    get assignment_interview_application_path(interview_application)

    assert_response :not_found
  end

  test "capable examiner cannot assign examiner that cannot interview target" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    capable = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    incapable = create_examiner_for(create_evaluation_target, monthly_interview_count: 1)
    sign_in_as(capable)

    patch assignment_interview_application_path(interview_application), params: {
      interview_application: {
        assigned_examiner_profile_id: incapable.examiner_profile.id,
        assignment_override_reason: "manual"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Assigned examiner profile must be able to interview target"
  end

  test "capable examiner cannot assign candidate self profile" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    interview_application = create_interview_application(candidate: candidate_examiner)
    self_profile = ExaminerProfile.create!(
      user: candidate_examiner,
      display_name: "Self #{SecureRandom.hex(4)}"
    )
    ExaminerSkillCapability.create!(
      examiner_profile: self_profile,
      evaluation_target: interview_application.exam_application.evaluation_target
    )
    actor = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    sign_in_as(actor)

    patch assignment_interview_application_path(interview_application), params: {
      interview_application: {
        assigned_examiner_profile_id: self_profile.id,
        assignment_override_reason: "manual"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Assigned examiner profile must not be the candidate"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  test "capable examiner cannot assign examiner that reached monthly limit" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    actor = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    limited = create_examiner_for(
      interview_application.exam_application.evaluation_target,
      monthly_interview_count: 1,
      max_monthly_interviews: 1
    )
    sign_in_as(actor)

    patch assignment_interview_application_path(interview_application), params: {
      interview_application: {
        assigned_examiner_profile_id: limited.examiner_profile.id,
        assignment_override_reason: "manual"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Assigned examiner profile has reached monthly interview limit"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  private

  def create_interview_application(candidate:)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
    InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)
  end

  def create_examiner_for(evaluation_target, monthly_interview_count:, max_monthly_interviews: nil)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(
      user: examiner,
      display_name: "Examiner #{SecureRandom.hex(4)}",
      monthly_interview_count: monthly_interview_count,
      max_monthly_interviews: max_monthly_interviews
    )
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
