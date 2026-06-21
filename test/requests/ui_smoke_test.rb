require "test_helper"

class UiSmokeTest < ActionDispatch::IntegrationTest
  test "candidate navigation focuses on exam applications and qualifications" do
    candidate = create_user_with_role(Role::CANDIDATE)
    sign_in_as(candidate)

    get exam_applications_path

    assert_response :success
    assert_includes response.body, "受験対象"
    assert_includes response.body, "受験表明"
    assert_includes response.body, "取得資格"
    assert_not_includes response.body, "レビューキュー"
  end

  test "examiner navigation includes review queue and candidate search" do
    target = create_evaluation_target
    examiner = create_examiner_for(target)
    sign_in_as(examiner)

    get evaluation_targets_path

    assert_response :success
    assert_includes response.body, "レビューキュー"
    assert_includes response.body, "受験者検索"
  end

  test "examiner without review capability does not see review queue navigation" do
    examiner = create_user_with_role(Role::EXAMINER)
    sign_in_as(examiner)

    get evaluation_targets_path

    assert_response :success
    assert_not_includes response.body, "レビューキュー"
    assert_includes response.body, "受験者検索"
  end

  test "exam application list shows status badges and detail link" do
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
    assert_includes response.body, "Declared"
    assert_includes response.body, application.display_name

    get exam_application_path(application)

    assert_response :success
    assert_includes response.body, "レビュー依頼を作成"
  end

  test "form error summary is shown on invalid exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    target = create_evaluation_target
    period = create_evaluation_period
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
    assert_includes response.body, "入力内容を確認してください"
    assert_includes response.body, "open exam application already exists"
  end

  test "blank exam application form selection is shown as form error" do
    candidate = create_user_with_role(Role::CANDIDATE)
    sign_in_as(candidate)

    post exam_applications_path, params: {
      exam_application: {
        evaluation_period_id: "",
        evaluation_target_id: ""
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "入力内容を確認してください"
    assert_includes response.body, "Evaluation period"
    assert_includes response.body, "Evaluation target"
  end

  test "qualification index has a useful empty state" do
    candidate = create_user_with_role(Role::CANDIDATE)
    sign_in_as(candidate)

    get user_qualifications_path

    assert_response :success
    assert_includes response.body, "取得資格はまだありません"
  end

  test "interview application form warns that it cannot be canceled" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
    application.update!(status: :review_approved)
    sign_in_as(candidate)

    get new_exam_application_interview_application_path(application)

    assert_response :success
    assert_includes response.body, "応募後は取消できません"
  end

  private

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

  def create_examiner_for(target)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: target)
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
