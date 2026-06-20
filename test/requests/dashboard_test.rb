require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  test "root redirects unauthenticated user to sign in" do
    get root_path

    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "candidate sees workflow dashboard after sign in" do
    candidate = create_user_with_role(Role::CANDIDATE)
    sign_in_as(candidate)

    get root_path

    assert_response :success
    assert_includes response.body, "評価スキル証跡ダッシュボード"
    assert_includes response.body, "受験者ワークフロー"
    assert_includes response.body, "受験対象を見る"
  end

  test "examiner sees review entry points" do
    target = create_evaluation_target
    examiner = create_user_with_role(Role::EXAMINER)
    create_examiner_profile(examiner, target)
    sign_in_as(examiner)

    get root_path

    assert_response :success
    assert_includes response.body, "評価官レビュー"
    assert_includes response.body, "レビューキュー"
    assert_includes response.body, "受験者検索"
  end

  test "sign in page shows local demo accounts" do
    get new_user_session_path

    assert_response :success
    assert_includes response.body, "デモアカウント"
    assert_includes response.body, "candidate@example.com"
    assert_includes response.body, "password123"
  end

  test "sign in page hides demo accounts outside local environments" do
    previous_setting = Rails.configuration.x.local_demo_enabled
    Rails.configuration.x.local_demo_enabled = false

    get new_user_session_path

    assert_response :success
    assert_not_includes response.body, "デモアカウント"
    assert_not_includes response.body, "candidate@example.com"
    assert_not_includes response.body, "password123"
  ensure
    Rails.configuration.x.local_demo_enabled = previous_setting
  end

  private

  def create_examiner_profile(user, target)
    profile = ExaminerProfile.create!(
      user: user,
      display_name: "Examiner #{SecureRandom.hex(4)}",
      monthly_interview_count: 0
    )
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: target)
    profile
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
