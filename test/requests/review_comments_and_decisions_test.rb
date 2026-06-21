require "test_helper"

class ReviewCommentsAndDecisionsTest < ActionDispatch::IntegrationTest
  test "capable examiner can show review detail" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    sign_in_as(examiner)

    get review_application_path(review_application)

    assert_response :success
    assert_includes response.body, review_application.display_name
  end

  test "incapable examiner cannot show review detail" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(create_evaluation_target)
    sign_in_as(examiner)

    get review_application_path(review_application)

    assert_response :not_found
  end

  test "capable examiner can add comment without changing review status" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    sign_in_as(examiner)

    assert_difference -> { ReviewComment.count }, 1 do
      post review_application_review_comments_path(review_application), params: {
        review_comment: {
          body_markdown: "Looks **good**"
        }
      }
    end

    assert_redirected_to review_application_path(review_application)
    assert review_application.reload.submitted?
    assert_includes ReviewComment.last.rendered_body_html, "<strong>good</strong>"
  end

  test "incapable examiner cannot add comment" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(create_evaluation_target)
    sign_in_as(examiner)

    post review_application_review_comments_path(review_application), params: {
      review_comment: {
        body_markdown: "not allowed"
      }
    }

    assert_response :not_found
  end

  test "dual role candidate examiner cannot comment on own review" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    review_application = create_review_application(candidate: candidate_examiner)
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Self Reviewer")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: review_application.exam_application.evaluation_target
    )
    sign_in_as(candidate_examiner)

    post review_application_review_comments_path(review_application), params: {
      review_comment: {
        body_markdown: "self comment"
      }
    }

    assert_response :forbidden
  end

  test "dual role candidate examiner can comment on other assigned review" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    review_application = create_review_application(candidate: create_user_with_role(Role::CANDIDATE))
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Dual Role Reviewer")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: review_application.exam_application.evaluation_target
    )
    sign_in_as(candidate_examiner)

    post review_application_review_comments_path(review_application), params: {
      review_comment: {
        body_markdown: "dual role comment"
      }
    }

    assert_redirected_to review_application_path(review_application)
    assert_equal candidate_examiner, ReviewComment.last.examiner
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
    sign_in_as(candidate_examiner)

    patch review_comment_path(comment), params: {
      review_comment: {
        body_markdown: "updated self comment"
      }
    }

    assert_response :forbidden
    assert_equal "existing self comment", comment.reload.body_markdown
  end

  test "capable examiner can approve review decision" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    sign_in_as(examiner)

    assert_difference -> { ReviewDecision.count }, 1 do
      post review_application_review_decisions_path(review_application), params: {
        review_decision: {
          decision: "approve"
        }
      }
    end

    assert_redirected_to review_application_path(review_application)
    assert review_application.reload.approved?
    assert review_application.exam_application.reload.review_approved?
  end

  test "dual role candidate examiner cannot decide own review" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    review_application = create_review_application(candidate: candidate_examiner)
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Self Reviewer")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: review_application.exam_application.evaluation_target
    )
    sign_in_as(candidate_examiner)

    post review_application_review_decisions_path(review_application), params: {
      review_decision: {
        decision: "approve"
      }
    }

    assert_response :forbidden
    assert review_application.reload.submitted?
  end

  test "dual role candidate examiner can decide other assigned review" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    review_application = create_review_application(candidate: create_user_with_role(Role::CANDIDATE))
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Dual Role Reviewer")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: review_application.exam_application.evaluation_target
    )
    sign_in_as(candidate_examiner)

    post review_application_review_decisions_path(review_application), params: {
      review_decision: {
        decision: "approve"
      }
    }

    assert_redirected_to review_application_path(review_application)
    assert review_application.reload.approved?
  end

  test "final review rejects additional decision" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    ReviewDecisions::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { decision: "approve" }
    )
    sign_in_as(examiner)

    post review_application_review_decisions_path(review_application), params: {
      review_decision: {
        decision: "reject",
        reason_markdown: "late"
      }
    }

    assert_response :forbidden
  end

  test "canceled review rejects comment update with unprocessable entity" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    comment = ReviewComments::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { body_markdown: "first" }
    )
    ReviewApplications::CancelService.call(review_application: review_application, actor: candidate)
    sign_in_as(examiner)

    patch review_comment_path(comment), params: {
      review_comment: {
        body_markdown: "updated"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Review application must accept comments"
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
