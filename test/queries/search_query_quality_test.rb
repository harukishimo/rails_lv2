require "test_helper"

class SearchQueryQualityTest < ActiveSupport::TestCase
  test "review queue search relation can be explained as database evidence" do
    target = create_evaluation_target
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: target,
      actor: candidate
    )
    ReviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate,
      attributes: {
        appeal_markdown: "query evidence",
        submissions_attributes: [
          {
            kind: "github_repository",
            title: "Repository",
            github_url: "https://github.com/harukishimo/rails_lv2"
          }
        ]
      }
    )

    relation = Search::ReviewQueueSearch.new(
      ReviewApplication.all,
      status: "submitted",
      evaluation_target_id: target.id,
      per_page: 10
    ).relation
    plan = explain_query_plan(relation)

    assert_includes plan, "review_applications"
    assert_includes plan, "exam_applications"
    assert_includes plan, "SEARCH"
  end

  private

  def explain_query_plan(relation)
    rows = ActiveRecord::Base.connection.execute("EXPLAIN QUERY PLAN #{relation.to_sql}")
    rows.map { |row| row.respond_to?(:to_h) ? row.to_h.values.join(" ") : row.to_s }.join("\n")
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
    framework = Framework.create!(name: "Rails #{SecureRandom.hex(4)}", programming_language: language)

    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: SkillLevel.create!(code: "Lv2-#{SecureRandom.hex(4)}", numeric_level: 2),
      external_knowledge_key: "ruby_lv2_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}"
    )
  end

  def create_user_with_role(code)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    user = User.create!(
      name: "User #{SecureRandom.hex(4)}",
      email: "user-#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    UserRole.create!(user: user, role: role)
    user
  end
end
