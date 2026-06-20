require "test_helper"

class ExaminerSuggestionServiceTest < ActiveSupport::TestCase
  test "suggests available examiner with lowest monthly interview count" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    target = interview_application.exam_application.evaluation_target
    busy_examiner = create_examiner_for(target, monthly_interview_count: 3)
    light_examiner = create_examiner_for(target, monthly_interview_count: 1)

    assert_equal light_examiner.examiner_profile,
                 ExaminerSuggestionService.call(interview_application: interview_application)
    assert_not_equal busy_examiner.examiner_profile,
                     ExaminerSuggestionService.call(interview_application: interview_application)
  end

  test "does not suggest inactive profile, interview-disabled profile, disabled capability, over-limit profile, or self" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    interview_application = create_interview_application(candidate: candidate_examiner)
    target = interview_application.exam_application.evaluation_target
    valid_examiner = create_examiner_for(target, monthly_interview_count: 2)
    create_examiner_for(target, active: false, monthly_interview_count: 0)
    create_examiner_for(target, can_interview: false, monthly_interview_count: 0)
    create_examiner_for(target, capability_can_interview: false, monthly_interview_count: 0)
    create_examiner_for(target, monthly_interview_count: 1, max_monthly_interviews: 1)
    self_profile = ExaminerProfile.create!(
      user: candidate_examiner,
      display_name: "Self #{SecureRandom.hex(4)}",
      monthly_interview_count: 0
    )
    ExaminerSkillCapability.create!(examiner_profile: self_profile, evaluation_target: target)

    assert_equal valid_examiner.examiner_profile,
                 ExaminerSuggestionService.call(interview_application: interview_application)
  end

  private

  def create_interview_application(candidate:)
    exam_application = ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
    InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)
  end

  def create_examiner_for(
    evaluation_target,
    active: true,
    can_interview: true,
    capability_can_interview: true,
    monthly_interview_count: 0,
    max_monthly_interviews: nil
  )
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(
      user: examiner,
      display_name: "Examiner #{SecureRandom.hex(4)}",
      can_interview: can_interview,
      monthly_interview_count: monthly_interview_count,
      max_monthly_interviews: max_monthly_interviews
    )
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: evaluation_target,
      can_interview: capability_can_interview
    )
    profile.update!(active: false) unless active
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
