require "test_helper"

class ReviewApplicationsTest < ActionDispatch::IntegrationTest
  test "candidate can open new review application form" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    sign_in_as(candidate)

    get new_exam_application_review_application_path(exam_application)

    assert_response :success
    assert_includes response.body, "New review application"
  end

  test "candidate can create review application with github repository submission" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    sign_in_as(candidate)

    assert_difference -> { ReviewApplication.count }, 1 do
      assert_difference -> { Submission.count }, 1 do
        post exam_application_review_applications_path(exam_application), params: {
          review_application: {
            appeal_markdown: "# Appeal\n\n**Evidence**",
            submissions_attributes: [
              {
                kind: "github_repository",
                title: "Repository",
                github_url: "https://github.com/harukishimo/rails_lv2"
              }
            ]
          }
        }
      end
    end

    review_application = ReviewApplication.last
    assert_redirected_to review_application_path(review_application)
    assert review_application.submitted?
    assert_includes review_application.rendered_appeal_html, "<strong>Evidence</strong>"
  end

  test "candidate cannot create submitted review application without evidence" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    sign_in_as(candidate)

    assert_no_difference -> { ReviewApplication.count } do
      post exam_application_review_applications_path(exam_application), params: {
        review_application: {
          appeal_markdown: "appeal only"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "review application must include a file or GitHub repository submission"
  end

  test "candidate can create review application with file submission" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    upload = uploaded_evidence_file
    sign_in_as(candidate)

    assert_difference -> { ReviewApplication.count }, 1 do
      assert_difference -> { Submission.count }, 1 do
        post exam_application_review_applications_path(exam_application), params: {
          review_application: {
            appeal_markdown: "file evidence",
            submissions_attributes: [
              {
                kind: "file",
                title: "Evidence file",
                file: upload
              }
            ]
          }
        }
      end
    end

    assert ReviewApplication.last.submissions.first.file.attached?
  ensure
    upload&.tempfile&.close
  end

  test "candidate can open edit review application form" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    sign_in_as(candidate)

    get edit_review_application_path(review_application)

    assert_response :success
    assert_includes response.body, "Edit #{review_application.display_name}"
  end

  test "candidate can see review application status history" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    sign_in_as(candidate)

    get review_application_path(review_application)

    assert_response :success
    assert_includes response.body, "状態変更履歴"
    assert_includes response.body, "Review application submitted"
  end

  test "candidate can update editable review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    sign_in_as(candidate)

    patch review_application_path(review_application), params: {
      review_application: {
        appeal_markdown: "updated **appeal**"
      }
    }

    assert_redirected_to review_application_path(review_application)
    review_application.reload
    assert_equal "updated **appeal**", review_application.appeal_markdown
    assert_includes review_application.rendered_appeal_html, "<strong>appeal</strong>"
  end

  test "candidate cannot update review application after parent exam is closed" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    ExamApplications::TransitionService.new(review_application.exam_application, actor: candidate).close!
    sign_in_as(candidate)

    patch review_application_path(review_application), params: {
      review_application: {
        appeal_markdown: "closed update"
      }
    }

    assert_response :forbidden
    assert_not_equal "closed update", review_application.reload.appeal_markdown
  end

  test "candidate can cancel review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    sign_in_as(candidate)

    patch cancel_review_application_path(review_application), params: {
      review_application: {
        cancel_reason: "wrong evidence"
      }
    }

    assert_redirected_to review_application_path(review_application)
    review_application.reload
    assert review_application.canceled?
    assert_not_nil review_application.canceled_at
    assert_equal "wrong evidence", review_application.cancel_reason
  end

  test "candidate cannot cancel review application after parent exam is closed" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    ExamApplications::TransitionService.new(review_application.exam_application, actor: candidate).close!
    sign_in_as(candidate)

    patch cancel_review_application_path(review_application), params: {
      review_application: {
        cancel_reason: "closed cancel"
      }
    }

    assert_response :forbidden
    assert_not review_application.reload.canceled?
  end

  test "candidate cannot create concurrent review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    sign_in_as(candidate)

    post exam_application_review_applications_path(review_application.exam_application), params: {
      review_application: {
        appeal_markdown: "second",
        submissions_attributes: [
          {
            kind: "github_repository",
            title: "Repository",
            github_url: "https://github.com/harukishimo/rails_lv2"
          }
        ]
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "in-progress review application already exists"
  end

  test "candidate cannot show another candidate review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    other_candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: other_candidate)
    sign_in_as(candidate)

    get review_application_path(review_application)

    assert_response :not_found
  end

  private

  def create_review_application(candidate:)
    exam_application = create_declared_exam_application(candidate: candidate)
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

  def create_declared_exam_application(candidate:)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
  end

  def uploaded_evidence_file
    file = Tempfile.new([ "evidence", ".txt" ])
    file.write("evidence")
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "text/plain")
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

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
