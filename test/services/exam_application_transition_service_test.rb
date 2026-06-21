require "test_helper"

class ExamApplicationTransitionServiceTest < ActiveSupport::TestCase
  test "transitions declared application through review states" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = create_declared_application(candidate: candidate)
    service = ExamApplications::TransitionService.new(application, actor: candidate)

    service.start_review!
    assert application.reviewing?

    service.approve_review!
    assert application.review_approved?
  end

  test "permits interview directly from declared application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = create_declared_application(candidate: candidate)

    ExamApplications::TransitionService.new(application, actor: candidate).permit_interview!

    assert application.review_approved?
    assert application.interview_permitted?
  end

  test "rejects invalid transition" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = create_declared_application(candidate: candidate)
    service = ExamApplications::TransitionService.new(application, actor: candidate)

    error = assert_raises(ExamApplications::TransitionService::InvalidTransitionError) do
      service.mark_passed!
    end
    assert_equal "cannot transition exam application from declared to passed", error.message
  end

  test "uses latest status under lock when stale instance transitions" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = create_declared_application(candidate: candidate)
    stale_application = ExamApplication.find(application.id)

    ExamApplications::TransitionService.new(application, actor: candidate).close!

    error = assert_raises(ExamApplications::TransitionService::InvalidTransitionError) do
      ExamApplications::TransitionService.new(stale_application, actor: candidate).start_review!
    end

    assert_equal "cannot transition exam application from closed to reviewing", error.message
    assert stale_application.reload.closed?
  end

  test "close stamps closed_at" do
    candidate = create_user_with_role(Role::CANDIDATE)
    application = create_declared_application(candidate: candidate)

    ExamApplications::TransitionService.new(application, actor: candidate).close!

    assert application.closed?
    assert_not_nil application.closed_at
  end

  private

  def create_declared_application(candidate:)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
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
