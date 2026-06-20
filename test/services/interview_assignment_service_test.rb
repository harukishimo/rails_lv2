require "test_helper"

class InterviewAssignmentServiceTest < ActiveSupport::TestCase
  test "assigns suggested examiner without override metadata and increments monthly count" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)

    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: examiner,
      examiner_profile: examiner.examiner_profile
    )

    interview_application.reload
    assert interview_application.examiner_assigned?
    assert_equal examiner.examiner_profile, interview_application.assigned_examiner_profile
    assert_nil interview_application.assignment_overridden_by
    assert_nil interview_application.assignment_override_reason
    assert_equal 1, examiner.examiner_profile.reload.monthly_interview_count
  end

  test "manual override saves actor and reason" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    suggested = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    override = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 2)

    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: suggested,
      examiner_profile: override.examiner_profile,
      reason: "domain familiarity"
    )

    interview_application.reload
    assert_equal override.examiner_profile, interview_application.assigned_examiner_profile
    assert_equal suggested, interview_application.assignment_overridden_by
    assert_equal "domain familiarity", interview_application.assignment_override_reason
    assert_equal 3, override.examiner_profile.reload.monthly_interview_count
  end

  test "manual override requires reason" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    suggested = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    override = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 2)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewApplications::AssignExaminerService.call(
        interview_application: interview_application,
        actor: suggested,
        examiner_profile: override.examiner_profile
      )
    end

    assert_includes error.record.errors[:assignment_override_reason], "is required for manual override"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  test "rejects examiner that cannot interview target" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    capable = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    incapable = create_examiner_for(create_evaluation_target, monthly_interview_count: 2)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewApplications::AssignExaminerService.call(
        interview_application: interview_application,
        actor: capable,
        examiner_profile: incapable.examiner_profile,
        reason: "manual"
      )
    end

    assert_includes error.record.errors[:assigned_examiner_profile], "must be able to interview target"
  end

  test "rejects candidate self profile assignment" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    interview_application = create_interview_application(candidate: candidate_examiner)
    self_profile = ExaminerProfile.create!(
      user: candidate_examiner,
      display_name: "Self #{SecureRandom.hex(4)}"
    )
    ExaminerSkillCapability.create!(
      examiner_profile: self_profile,
      evaluation_target: interview_application.exam_application.evaluation_target
    )
    actor = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewApplications::AssignExaminerService.call(
        interview_application: interview_application,
        actor: actor,
        examiner_profile: self_profile,
        reason: "manual"
      )
    end

    assert_includes error.record.errors[:assigned_examiner_profile], "must not be the candidate"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  test "rejects examiner that reached monthly interview limit" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    actor = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    limited = create_examiner_for(
      interview_application.exam_application.evaluation_target,
      monthly_interview_count: 1,
      max_monthly_interviews: 1
    )

    error = assert_raises(ActiveRecord::RecordInvalid) do
      InterviewApplications::AssignExaminerService.call(
        interview_application: interview_application,
        actor: actor,
        examiner_profile: limited.examiner_profile,
        reason: "manual"
      )
    end

    assert_includes error.record.errors[:assigned_examiner_profile], "has reached monthly interview limit"
    assert_nil interview_application.reload.assigned_examiner_profile
  end

  test "reassignment decrements previous examiner and increments new examiner" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    first = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 0)
    second = create_examiner_for(interview_application.exam_application.evaluation_target, monthly_interview_count: 1)
    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: first,
      examiner_profile: first.examiner_profile
    )

    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: first,
      examiner_profile: second.examiner_profile,
      reason: "load adjustment"
    )

    assert_equal second.examiner_profile, interview_application.reload.assigned_examiner_profile
    assert_equal 0, first.examiner_profile.reload.monthly_interview_count
    assert_equal 2, second.examiner_profile.reload.monthly_interview_count
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

  def create_examiner_for(evaluation_target, monthly_interview_count:, max_monthly_interviews: nil)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(
      user: examiner,
      display_name: "Examiner #{SecureRandom.hex(4)}",
      monthly_interview_count: monthly_interview_count,
      max_monthly_interviews: max_monthly_interviews
    )
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
