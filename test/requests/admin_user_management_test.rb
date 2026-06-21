require "test_helper"

class AdminUserManagementTest < ActionDispatch::IntegrationTest
  test "admin can list users and open management entry points" do
    admin = create_user_with_role(Role::ADMIN, name: "Admin User")
    create_user_with_role(Role::CANDIDATE, name: "Candidate User")

    sign_in_as(admin)
    get admin_dashboard_path

    assert_response :success
    assert_includes response.body, "ユーザー管理"
    assert_includes response.body, "評価官管理"

    get admin_users_path, params: { keyword: "Candidate" }

    assert_response :success
    assert_includes response.body, "Candidate User"
  end

  test "candidate cannot access admin user management" do
    candidate = create_user_with_role(Role::CANDIDATE)

    sign_in_as(candidate)
    get admin_users_path

    assert_response :forbidden
  end

  test "admin can create an examiner user and examiner profile is prepared" do
    admin = create_user_with_role(Role::ADMIN)
    examiner_role = find_or_create_role(Role::EXAMINER)
    candidate_role = find_or_create_role(Role::CANDIDATE)

    sign_in_as(admin)

    assert_difference -> { User.count }, 1 do
      assert_difference -> { ExaminerProfile.count }, 1 do
        post admin_users_path, params: {
          user: {
            name: "New Examiner",
            email: "new-examiner@example.com",
            password: "password123",
            password_confirmation: "password123",
            active: "1",
            role_codes: [ examiner_role.code, candidate_role.code ]
          }
        }
      end
    end

    user = User.find_by!(email: "new-examiner@example.com")
    assert_redirected_to admin_user_path(user)
    assert user.examiner?
    assert user.candidate?
    assert_equal "New Examiner", user.examiner_profile.display_name
  end

  test "admin can update user roles and active flag" do
    admin = create_user_with_role(Role::ADMIN)
    user = create_user_with_role(Role::CANDIDATE)
    find_or_create_role(Role::EXAMINER)

    sign_in_as(admin)
    patch admin_user_path(user), params: {
      user: {
        name: "Updated User",
        email: user.email,
        password: "",
        password_confirmation: "",
        active: "0",
        role_codes: [ Role::EXAMINER ]
      }
    }

    assert_redirected_to admin_user_path(user)
    user.reload
    assert_equal "Updated User", user.name
    assert_not user.active?
    assert user.examiner?
    assert_not user.candidate?
    assert user.examiner_profile.present?
  end

  test "admin deactivates examiner profile when examiner role is removed" do
    admin = create_user_with_role(Role::ADMIN)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(
      user: examiner,
      display_name: "Retiring Examiner",
      active: true,
      can_review: true,
      can_interview: true
    )
    find_or_create_role(Role::CANDIDATE)

    sign_in_as(admin)
    patch admin_user_path(examiner), params: {
      user: {
        name: examiner.name,
        email: examiner.email,
        password: "",
        password_confirmation: "",
        active: "1",
        role_codes: [ Role::CANDIDATE ]
      }
    }

    assert_redirected_to admin_user_path(examiner)
    examiner.reload
    profile.reload
    assert_not examiner.examiner?
    assert examiner.candidate?
    assert_not profile.active?
    assert_not profile.can_review?
    assert_not profile.can_interview?
  end

  test "admin can grant examiner review and interview capabilities" do
    admin = create_user_with_role(Role::ADMIN)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Capable Examiner")
    target = create_evaluation_target
    other_target = create_evaluation_target

    sign_in_as(admin)
    patch admin_examiner_profile_path(profile), params: {
      examiner_profile: {
        display_name: "Senior Examiner",
        active: "1",
        can_review: "1",
        can_interview: "1",
        monthly_interview_count: "2",
        max_monthly_interviews: "6",
        review_evaluation_target_ids: [ target.id ],
        interview_evaluation_target_ids: [ target.id, other_target.id ]
      }
    }

    assert_redirected_to admin_examiner_profiles_path
    profile.reload
    assert_equal "Senior Examiner", profile.display_name
    assert_equal 2, profile.monthly_interview_count
    assert_equal 6, profile.max_monthly_interviews
    assert profile.can_evaluate?(target)
    assert profile.can_interview_for?(target)
    assert_not profile.can_evaluate?(other_target)
    assert profile.can_interview_for?(other_target)
  end

  test "admin can search examiners by assigned evaluation target" do
    admin = create_user_with_role(Role::ADMIN)
    target = create_evaluation_target
    matched = create_examiner_for(target, display_name: "Ruby Reviewer")
    create_examiner_for(create_evaluation_target, display_name: "Other Reviewer")

    sign_in_as(admin)
    get admin_examiner_profiles_path, params: { evaluation_target_id: target.id, keyword: "Ruby" }

    assert_response :success
    assert_includes response.body, matched.examiner_profile.display_name
    assert_not_includes response.body, "Other Reviewer"
  end

  test "candidate cannot access examiner profile management" do
    candidate = create_user_with_role(Role::CANDIDATE)

    sign_in_as(candidate)
    get admin_examiner_profiles_path

    assert_response :forbidden
  end

  private

  def create_examiner_for(evaluation_target, display_name:)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: display_name)
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: evaluation_target)
    examiner
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

  def create_user_with_role(code, name: "User")
    role = find_or_create_role(code)
    user = User.create!(
      name: name,
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    user
  end

  def find_or_create_role(code)
    Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
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
