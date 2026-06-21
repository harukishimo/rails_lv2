require "test_helper"

class ReviewCommentDecisionForeignKeyTest < ActiveSupport::TestCase
  test "database rejects review comment without existing review application" do
    examiner = create_user_with_role(Role::EXAMINER)
    now = Time.current

    assert_raises(ActiveRecord::InvalidForeignKey) do
      ReviewComment.insert_all!([
        {
          review_application_id: -1,
          examiner_id: examiner.id,
          body_markdown: "comment",
          rendered_body_html: "<p>comment</p>",
          lock_version: 0,
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database rejects review decision without existing examiner" do
    review_application = create_review_application
    now = Time.current

    assert_raises(ActiveRecord::InvalidForeignKey) do
      ReviewDecision.insert_all!([
        {
          review_application_id: review_application.id,
          examiner_id: -1,
          decision: ReviewDecision.decisions.fetch("approve"),
          decided_at: now,
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  private

  def create_review_application
    candidate = create_user_with_role(Role::CANDIDATE)
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
