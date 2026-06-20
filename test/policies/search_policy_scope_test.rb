require "test_helper"

class SearchPolicyScopeTest < ActiveSupport::TestCase
  test "evaluation target scope hides inactive targets from non admins" do
    candidate = create_user_with_role(Role::CANDIDATE)
    active_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    inactive_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3", active: false)

    scoped_targets = EvaluationTargetPolicy::Scope.new(candidate, EvaluationTarget.all).resolve

    assert_includes scoped_targets, active_target
    assert_not_includes scoped_targets, inactive_target
  end

  test "examiner candidate scope only includes candidates for capable targets" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    ruby_candidate = create_user_with_role(Role::CANDIDATE, name: "Ruby Candidate")
    go_candidate = create_user_with_role(Role::CANDIDATE, name: "Go Candidate")
    create_exam_application(candidate: ruby_candidate, target: ruby_target)
    create_exam_application(candidate: go_candidate, target: go_target)
    examiner = create_examiner_for(ruby_target)

    scoped_candidates = UserPolicy::Scope.new(examiner, User.all).resolve

    assert_includes scoped_candidates, ruby_candidate
    assert_not_includes scoped_candidates, go_candidate
  end

  test "review application scope excludes active but not reviewable capabilities" do
    target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    review_application = create_review_application(candidate: create_user_with_role(Role::CANDIDATE), target: target)
    examiner = create_examiner_for(target, can_review: false)

    visible_reviews = ReviewApplicationPolicy::Scope.new(examiner, ReviewApplication.all).resolve
    queued_reviews = ReviewApplicationPolicy::QueueScope.new(examiner, ReviewApplication.all).resolve

    assert_not_includes visible_reviews, review_application
    assert_not_includes queued_reviews, review_application
  end

  test "review queue scope does not include candidate-owned reviews for hybrid users" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    hybrid_user = create_user_with_role(Role::CANDIDATE, name: "Hybrid User")
    add_role(hybrid_user, Role::EXAMINER)
    profile = ExaminerProfile.create!(user: hybrid_user, display_name: "Hybrid #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: ruby_target, can_review: true)
    visible_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE), target: ruby_target)
    own_non_capable_review = create_review_application(candidate: hybrid_user, target: go_target)
    own_capable_review = create_review_application(candidate: hybrid_user, target: ruby_target)

    queued_reviews = ReviewApplicationPolicy::QueueScope.new(hybrid_user, ReviewApplication.all).resolve

    assert_includes queued_reviews, visible_review
    assert_not_includes queued_reviews, own_non_capable_review
    assert_not_includes queued_reviews, own_capable_review
  end

  test "user qualification scope follows candidate ownership and examiner capabilities" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    ruby_candidate = create_user_with_role(Role::CANDIDATE, name: "Ruby Candidate")
    go_candidate = create_user_with_role(Role::CANDIDATE, name: "Go Candidate")
    ruby_examiner = create_examiner_for(ruby_target)
    go_examiner = create_examiner_for(go_target)
    ruby_qualification = create_user_qualification(
      user: ruby_candidate,
      target: ruby_target,
      exam_application: create_exam_application(candidate: ruby_candidate, target: ruby_target),
      granted_by: ruby_examiner
    )
    go_qualification = create_user_qualification(
      user: go_candidate,
      target: go_target,
      exam_application: create_exam_application(candidate: go_candidate, target: go_target),
      granted_by: go_examiner
    )

    candidate_scope = UserQualificationPolicy::Scope.new(ruby_candidate, UserQualification.all).resolve
    examiner_scope = UserQualificationPolicy::Scope.new(ruby_examiner, UserQualification.all).resolve

    assert_includes candidate_scope, ruby_qualification
    assert_not_includes candidate_scope, go_qualification
    assert_includes examiner_scope, ruby_qualification
    assert_not_includes examiner_scope, go_qualification
  end

  private

  def create_review_application(candidate:, target:)
    exam_application = create_exam_application(candidate: candidate, target: target)
    ReviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate,
      attributes: {
        appeal_markdown: "appeal",
        submissions_attributes: [
          {
            kind: "github_repository",
            title: "Repository",
            github_url: "https://github.com/harukishimo/rails_lv2"
          }
        ]
      }
    )
  end

  def create_exam_application(candidate:, target:)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: target,
      actor: candidate
    )
  end

  def create_user_qualification(user:, target:, exam_application:, granted_by:)
    UserQualification.create!(
      user: user,
      evaluation_target: target,
      exam_application: exam_application,
      acquired_on: Date.current,
      granted_by: granted_by
    )
  end

  def create_examiner_for(target, can_review: true, can_interview: true)
    examiner = create_user_with_role(Role::EXAMINER, name: "Examiner")
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: target,
      can_review: can_review,
      can_interview: can_interview
    )
    examiner
  end

  def create_evaluation_period
    EvaluationPeriod.create!(
      name: "Period #{SecureRandom.hex(4)}",
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year
    )
  end

  def create_evaluation_target(language_name:, framework_name:, level_code:, active: true)
    language = ProgrammingLanguage.create!(name: "#{language_name} #{SecureRandom.hex(4)}")
    framework = if framework_name
      Framework.create!(name: "#{framework_name} #{SecureRandom.hex(4)}", programming_language: language)
    end
    skill_level = SkillLevel.create!(code: "#{level_code}-#{SecureRandom.hex(4)}", numeric_level: level_code.delete("^0-9").to_i)

    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: skill_level,
      external_knowledge_key: "#{language_name.downcase}_#{level_code.downcase}_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}",
      active: active
    )
  end

  def create_user_with_role(code, name: "User")
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

  def add_role(user, code)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    UserRole.create!(user: user, role: role)
  end
end
