require "test_helper"

class ReviewApplicationPolicyTest < ActiveSupport::TestCase
  test "capable examiner can show comment and decide review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    policy = ReviewApplicationPolicy.new(examiner, review_application)

    assert policy.show?
    assert policy.comment?
    assert policy.decide?
  end

  test "incapable examiner cannot show comment or decide review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(create_evaluation_target)
    policy = ReviewApplicationPolicy.new(examiner, review_application)

    assert_not policy.show?
    assert_not policy.comment?
    assert_not policy.decide?
  end

  test "candidate can show own review but cannot comment or decide" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    policy = ReviewApplicationPolicy.new(candidate, review_application)

    assert policy.show?
    assert_not policy.comment?
    assert_not policy.decide?
  end

  test "dual role candidate examiner cannot comment or decide own review" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    review_application = create_review_application(candidate: candidate_examiner)
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Self Reviewer")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: review_application.exam_application.evaluation_target
    )
    policy = ReviewApplicationPolicy.new(candidate_examiner, review_application)

    assert policy.show?
    assert_not policy.comment?
    assert_not policy.decide?
  end

  test "dual role candidate examiner can act on other assigned review" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    own_review = create_review_application(candidate: candidate_examiner)
    other_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE))
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Dual Role Reviewer")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: other_review.exam_application.evaluation_target
    )

    resolved = ReviewApplicationPolicy::Scope.new(candidate_examiner, ReviewApplication).resolve
    policy = ReviewApplicationPolicy.new(candidate_examiner, other_review)

    assert_includes resolved, own_review
    assert_includes resolved, other_review
    assert policy.show?
    assert policy.comment?
    assert policy.decide?
  end

  test "dual role candidate examiner cannot update existing own review comment" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    review_application = create_review_application(candidate: candidate_examiner)
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Self Reviewer")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: review_application.exam_application.evaluation_target
    )
    comment = ReviewComment.create!(
      review_application: review_application,
      examiner: candidate_examiner,
      body_markdown: "existing self comment"
    )

    assert_not ReviewCommentPolicy.new(candidate_examiner, comment).update?
  end

  test "capable examiner scope only includes assigned evaluation targets" do
    candidate = create_user_with_role(Role::CANDIDATE)
    visible_review = create_review_application(candidate: candidate)
    hidden_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE))
    examiner = create_examiner_for(visible_review.exam_application.evaluation_target)

    resolved = ReviewApplicationPolicy::Scope.new(examiner, ReviewApplication).resolve

    assert_includes resolved, visible_review
    assert_not_includes resolved, hidden_review
  end

  test "capable examiner cannot access candidate draft review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    draft_review = create_draft_review_application(candidate: candidate)
    examiner = create_examiner_for(draft_review.exam_application.evaluation_target)
    policy = ReviewApplicationPolicy.new(examiner, draft_review)
    resolved = ReviewApplicationPolicy::Scope.new(examiner, ReviewApplication).resolve

    assert_not policy.show?
    assert_not policy.comment?
    assert_not policy.decide?
    assert_not_includes resolved, draft_review
  end

  private

  def create_review_application(candidate:)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )

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

  def create_draft_review_application(candidate:)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )

    ReviewApplication.create!(
      exam_application: exam_application,
      sequence_number: 1,
      status: :draft,
      appeal_markdown: "draft appeal"
    )
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
end
