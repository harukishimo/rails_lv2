require "test_helper"

class DemoSeedTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  test "seed data is idempotent and creates local demo accounts" do
    interview_schedule_count = nil

    assert_nothing_raised do
      Rails.application.load_seed
      Rails.application.load_seed
      interview_schedule_count = InterviewSchedule.count
      travel 1.day do
        Rails.application.load_seed
      end
    end

    assert_equal interview_schedule_count, InterviewSchedule.count

    admin = User.find_by!(email: "admin@example.com")
    candidate = User.find_by!(email: "candidate@example.com")
    passed_candidate = User.find_by!(email: "candidate8@example.com")
    examiner = User.find_by!(email: "examiner@example.com")

    assert admin.admin?
    assert candidate.candidate?
    assert examiner.examiner?
    assert candidate.valid_password?("password123")

    assert_equal [ "クラウド", "バックエンド", "フロントエンド", "プロジェクトマネージャ", "要件定義", "試験・QA" ].sort,
                 SkillArea.active.pluck(:name).sort
    assert_equal [ "Go", "Java", "Next", "Node", "PHP", "Ruby", "Vue", "言語なし" ].sort,
                 ProgrammingLanguage.active.pluck(:name).sort
    assert_equal [ "Lv1", "Lv2", "Lv3" ], SkillLevel.active.order(:numeric_level).pluck(:code)
    assert_equal 22, EvaluationTarget.active.count
    assert_not EvaluationTarget.active.joins(:skill_area, :programming_language)
                               .exists?(skill_areas: { name: "フロントエンド" }, programming_languages: { name: "Ruby" })
    assert_not EvaluationTarget.active.joins(:skill_area, :programming_language)
                               .exists?(skill_areas: { name: "バックエンド" }, programming_languages: { name: "Next" })
    assert EvaluationTarget.active.joins(:skill_area, :programming_language)
                           .exists?(skill_areas: { name: "バックエンド" }, programming_languages: { name: "Ruby" })
    assert EvaluationTarget.active.joins(:skill_area, :programming_language)
                           .exists?(skill_areas: { name: "フロントエンド" }, programming_languages: { name: "Next" })
    assert_equal [ "2025 下期", "2026 上期", "2026 下期", "2027 上期", "2027 下期" ].sort,
                 EvaluationPeriod.where(name: [ "2025 下期", "2026 上期", "2026 下期", "2027 上期", "2027 下期" ])
                                 .pluck(:name)
                                 .sort
    assert_not EvaluationPeriod.find_by!(name: "2025 下期").active?

    assert_equal 8, User.joins(:roles).where(roles: { code: Role::CANDIDATE }).where("users.email LIKE ?", "candidate%@example.com").distinct.count
    assert_equal 27, User.joins(:roles).where(roles: { code: Role::EXAMINER }).where("users.email LIKE ?", "examiner%@example.com").distinct.count
    assert examiner.examiner_profile.can_evaluate?(EvaluationTarget.find_by!(external_knowledge_key: "ruby_on_rails_lv2"))
    assert ReviewApplication.submitted.joins(:exam_application).where(exam_applications: { candidate_id: candidate.id }).exists?
    assert ReviewApplication.returned.exists?
    assert ReviewApplication.approved.exists?
    assert ReviewApplication.rejected.exists?
    assert ReviewApplication.canceled.exists?
    assert InterviewApplication.requested.exists?
    assert InterviewApplication.examiner_assigned.exists?
    assert InterviewApplication.schedule_requested.exists?
    assert InterviewApplication.scheduled.exists?
    assert InterviewApplication.calendar_created.exists?
    assert InterviewApplication.completed.exists?
    assert passed_candidate.user_qualifications.exists?
    assert StatusChangeEvent.exists?
  end
end
