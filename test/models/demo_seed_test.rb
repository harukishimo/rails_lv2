require "test_helper"

class DemoSeedTest < ActiveSupport::TestCase
  test "seed data is idempotent and creates local demo accounts" do
    assert_nothing_raised do
      Rails.application.load_seed
      Rails.application.load_seed
    end

    admin = User.find_by!(email: "admin@example.com")
    candidate = User.find_by!(email: "candidate@example.com")
    examiner = User.find_by!(email: "examiner@example.com")

    assert admin.admin?
    assert candidate.candidate?
    assert examiner.examiner?
    assert candidate.valid_password?("password123")
    assert examiner.examiner_profile.can_evaluate?(EvaluationTarget.find_by!(external_knowledge_key: "ruby_on_rails_lv2"))
    assert ReviewApplication.submitted.joins(:exam_application).where(exam_applications: { candidate_id: candidate.id }).exists?
    assert candidate.user_qualifications.exists?
  end
end
