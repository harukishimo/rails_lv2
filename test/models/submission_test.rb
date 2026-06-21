require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  test "accepts github repository URL" do
    review_application = create_review_application

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Repository",
      github_url: "https://github.com/harukishimo/rails_lv2"
    )

    assert submission.valid?
  end

  test "accepts github pull request URL" do
    review_application = create_review_application

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Pull request",
      github_url: "https://github.com/harukishimo/rails_lv2/pull/38"
    )

    assert submission.valid?
  end

  test "rejects non github repository URL" do
    review_application = create_review_application

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Repository",
      github_url: "https://example.com/not/repository"
    )

    assert_not submission.valid?
    assert_includes submission.errors[:github_url], "must be a GitHub URL"
  end

  test "accepts github URL with query string" do
    review_application = create_review_application

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Repository",
      github_url: "https://github.com/harukishimo/rails_lv2?tab=readme"
    )

    assert submission.valid?
  end

  test "accepts github URL with fragment" do
    review_application = create_review_application

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Repository",
      github_url: "https://github.com/harukishimo/rails_lv2#readme"
    )

    assert submission.valid?
  end

  test "rejects github root URL" do
    review_application = create_review_application

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Repository",
      github_url: "https://github.com/"
    )

    assert_not submission.valid?
    assert_includes submission.errors[:github_url], "must be a GitHub URL"
  end

  test "accepts file submission with attachment" do
    review_application = create_review_application
    submission = review_application.submissions.build(kind: :file, title: "Evidence file")
    submission.file.attach(
      io: StringIO.new("evidence"),
      filename: "evidence.txt",
      content_type: "text/plain"
    )

    assert submission.valid?
    submission.save!
    assert submission.file.attached?
  end

  test "rejects file submission larger than 20MB" do
    review_application = create_review_application
    submission = review_application.submissions.build(kind: :file, title: "Evidence file")
    submission.file.attach(
      io: StringIO.new("x" * (Submission::MAX_FILE_SIZE + 1)),
      filename: "evidence.pdf",
      content_type: "application/pdf"
    )

    assert_not submission.valid?
    assert_includes submission.errors[:file], "must be 20MB or smaller"
  end

  test "rejects file submission with disallowed extension" do
    review_application = create_review_application
    submission = review_application.submissions.build(kind: :file, title: "Evidence file")
    attach_file(submission, filename: "evidence.exe")

    assert_not submission.valid?
    assert_includes submission.errors[:file], "must have an allowed extension"
  end

  test "rejects file submission without attachment" do
    review_application = create_review_application
    submission = review_application.submissions.build(kind: :file, title: "Evidence file")

    assert_not submission.valid?
    assert_includes submission.errors[:file], "must be attached for file submissions"
  end

  test "rejects updates when parent review is canceled" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    ReviewApplications::CancelService.call(review_application: review_application, actor: candidate)

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Repository",
      github_url: "https://github.com/harukishimo/rails_lv2"
    )

    assert_not submission.valid?
    assert_includes submission.errors[:review_application], "must be editable"
  end

  test "rejects updates when parent exam application is closed" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    ExamApplications::TransitionService.new(review_application.exam_application, actor: candidate).close!

    submission = review_application.submissions.build(
      kind: :github_repository,
      title: "Repository",
      github_url: "https://github.com/harukishimo/rails_lv2"
    )

    assert_not submission.valid?
    assert_includes submission.errors[:review_application], "must be editable"
  end

  private

  def attach_file(submission, filename:)
    submission.file.attach(
      io: StringIO.new("evidence"),
      filename: filename,
      content_type: "application/octet-stream"
    )
  end

  def create_review_application(candidate: create_user_with_role(Role::CANDIDATE))
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
end
