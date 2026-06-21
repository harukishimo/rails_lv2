require "test_helper"

class ExamApplicationsTest < ActionDispatch::IntegrationTest
  test "candidate can create exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target

    sign_in_as(candidate)

    assert_difference -> { ExamApplication.count }, 1 do
      post exam_applications_path, params: {
        exam_application: {
          evaluation_period_id: period.id,
          evaluation_target_id: target.id
        }
      }
    end

    application = ExamApplication.last
    assert_redirected_to exam_application_path(application)
    assert_equal candidate, application.candidate
    assert application.declared?
  end

  test "candidate cannot create duplicate open exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    period = create_evaluation_period
    target = create_evaluation_target
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: period,
      evaluation_target: target,
      actor: candidate
    )

    sign_in_as(candidate)
    post exam_applications_path, params: {
      exam_application: {
        evaluation_period_id: period.id,
        evaluation_target_id: target.id
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "同じ評価期・受験者・受験対象の進行中の受験はすでに存在します"
  end

  test "candidate sees own exam application in index and detail" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )

    sign_in_as(candidate)
    get exam_applications_path

    assert_response :success
    assert_includes response.body, "受験ID: #{application.id}"

    get exam_application_path(application)

    assert_response :success
    assert_includes response.body, application.display_name
    assert_includes response.body, "状態変更履歴"
    assert_includes response.body, "受験表明"
    assert_not_includes response.body, "面談応募へ進む"
    assert_includes response.body, "面談応募は評価官が許可すると作成できます"
  end

  test "capable examiner can permit interview from exam application detail" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
    examiner = create_examiner_for(application.evaluation_target)
    sign_in_as(examiner)

    get exam_application_path(application)

    assert_response :success
    assert_includes response.body, "面談を許可する"

    assert_difference -> { StatusChangeEvent.where(subject: application).count }, 1 do
      patch permit_interview_exam_application_path(application)
    end

    assert_redirected_to exam_application_path(application)
    assert application.reload.interview_permitted?

    delete destroy_user_session_path
    sign_in_as(candidate)
    get exam_application_path(application)

    assert_response :success
    assert_includes response.body, "面談応募へ進む"
    assert_not_includes response.body, "面談を許可する"
  end

  test "incapable examiner cannot see or permit exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
    examiner = create_examiner_for(create_evaluation_target)
    sign_in_as(examiner)

    get exam_application_path(application)

    assert_response :not_found

    patch permit_interview_exam_application_path(application)

    assert_response :not_found
    assert application.reload.declared?
  end

  test "candidate cannot see another candidate exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    other_candidate = create_user_with_role(Role::CANDIDATE)
    application = ExamApplications::CreateService.call(
      candidate: other_candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: other_candidate
    )

    sign_in_as(candidate)
    get exam_application_path(application)

    assert_response :not_found
  end

  test "examiner cannot create exam application" do
    examiner = create_user_with_role(Role::EXAMINER)
    period = create_evaluation_period
    target = create_evaluation_target

    sign_in_as(examiner)
    post exam_applications_path, params: {
      exam_application: {
        evaluation_period_id: period.id,
        evaluation_target_id: target.id
      }
    }

    assert_response :forbidden
  end

  private

  def create_evaluation_period
    EvaluationPeriod.create!(
      name: "Period #{SecureRandom.hex(4)}",
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year
    )
  end

  def create_evaluation_target(attributes = {})
    language = ProgrammingLanguage.create!(name: "Ruby #{SecureRandom.hex(4)}")
    framework = Framework.create!(name: "Ruby on Rails #{SecureRandom.hex(4)}", programming_language: language)

    EvaluationTarget.create!({
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv#{rand(1000..9999)}", numeric_level: 2),
      external_knowledge_key: "ruby_on_rails_lv2_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}"
    }.merge(attributes))
  end

  def create_examiner_for(evaluation_target)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: evaluation_target)
    examiner
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

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
