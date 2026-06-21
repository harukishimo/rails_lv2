require "test_helper"

class JapaneseUiTest < ActionDispatch::IntegrationTest
  test "exam application list shows Japanese enum labels" do
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
    assert_includes response.body, application.display_name
    assert_includes response.body, "受験表明済み"
    assert_not_includes response.body, ">declared<"
  end

  test "form error summary uses Japanese ActiveModel messages in browser requests" do
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
    assert_includes response.body, "入力内容を確認してください"
    assert_includes response.body, "同じ評価期・受験者・受験対象の進行中の受験はすでに存在します"
  end

  test "review application form shows Japanese submission kind options" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )

    sign_in_as(candidate)
    get new_exam_application_review_application_path(exam_application)

    assert_response :success
    assert_includes response.body, "GitHubリポジトリ"
    assert_includes response.body, "補足資料"
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
