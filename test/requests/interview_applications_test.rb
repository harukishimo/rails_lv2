require "test_helper"

class InterviewApplicationsTest < ActionDispatch::IntegrationTest
  test "candidate can open new interview application form with non-cancelable warning" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_review_approved_exam_application(candidate: candidate)
    sign_in_as(candidate)

    get new_exam_application_interview_application_path(exam_application)

    assert_response :success
    assert_includes response.body, "応募後は取消できません"
  end

  test "candidate can create interview application and sees unassigned examiner" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_review_approved_exam_application(candidate: candidate)
    sign_in_as(candidate)

    assert_difference -> { InterviewApplication.count }, 1 do
      post exam_application_interview_application_path(exam_application)
    end

    interview_application = InterviewApplication.last
    assert_redirected_to interview_application_path(interview_application)

    follow_redirect!
    assert_includes response.body, "面談評価官: 面接官未定"
    assert_includes response.body, "状態変更履歴"
    assert_includes response.body, "面談応募"
    assert exam_application.reload.interview_requested?
  end

  test "candidate cannot create interview application before review approval" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    sign_in_as(candidate)

    get new_exam_application_interview_application_path(exam_application)

    assert_redirected_to exam_application_path(exam_application)
    follow_redirect!
    assert_includes response.body, "面談応募は評価官が許可すると作成できます"

    assert_no_difference -> { InterviewApplication.count } do
      post exam_application_interview_application_path(exam_application)
    end

    assert_redirected_to exam_application_path(exam_application)
  end

  test "candidate cannot create interview application without existing own exam application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    other_candidate = create_user_with_role(Role::CANDIDATE)
    other_exam_application = create_declared_exam_application(candidate: other_candidate)
    sign_in_as(candidate)

    assert_no_difference -> { InterviewApplication.count } do
      post exam_application_interview_application_path(other_exam_application)
    end

    assert_response :not_found
  end

  test "candidate cannot create duplicate interview application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_review_approved_exam_application(candidate: candidate)
    InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)
    sign_in_as(candidate)

    assert_no_difference -> { InterviewApplication.count } do
      post exam_application_interview_application_path(exam_application)
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "受験はすでに存在します"
  end

  test "interview application has no cancel route" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    sign_in_as(candidate)

    delete interview_application_path(interview_application)

    assert_response :not_found
    assert interview_application.reload.requested?
  end

  test "candidate can create future interview schedule" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    assign_interview_application(interview_application)
    starts_at = future_quarter_hour(days: 2)
    sign_in_as(candidate)

    assert_difference -> { InterviewSchedule.count }, 1 do
      post interview_application_interview_schedules_path(interview_application), params: {
        interview_schedule: {
          starts_at: starts_at,
          ends_at: starts_at + 30.minutes
        }
      }
    end

    assert_redirected_to interview_application_path(interview_application)
    assert InterviewSchedule.last.requested?
    assert interview_application.reload.schedule_requested?
  end

  test "candidate cannot create schedule for another candidate interview application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    other_candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: other_candidate)
    starts_at = future_quarter_hour(days: 2)
    sign_in_as(candidate)

    assert_no_difference -> { InterviewSchedule.count } do
      post interview_application_interview_schedules_path(interview_application), params: {
        interview_schedule: {
          starts_at: starts_at,
          ends_at: starts_at + 30.minutes
        }
      }
    end

    assert_response :not_found
  end

  test "candidate can create schedule from string datetime in Asia Tokyo time zone" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    assign_interview_application(interview_application)
    starts_at = future_quarter_hour(days: 2)
    ends_at = starts_at + 30.minutes
    sign_in_as(candidate)

    post interview_application_interview_schedules_path(interview_application), params: {
      interview_schedule: {
        starts_at: starts_at.strftime("%Y-%m-%d %H:%M:%S"),
        ends_at: ends_at.strftime("%Y-%m-%d %H:%M:%S")
      }
    }

    assert_redirected_to interview_application_path(interview_application)
    assert_equal "Asia/Tokyo", Time.zone.name
    assert_equal Time.zone.parse(starts_at.strftime("%Y-%m-%d %H:%M:%S")), InterviewSchedule.last.starts_at
  end

  test "candidate cannot create past interview schedule" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    assign_interview_application(interview_application)
    sign_in_as(candidate)

    assert_no_difference -> { InterviewSchedule.count } do
      post interview_application_interview_schedules_path(interview_application), params: {
        interview_schedule: {
          starts_at: 1.hour.ago,
          ends_at: 30.minutes.ago
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "開始日時は未来の日時を指定してください"
  end

  test "candidate cannot create interview schedule with starts_at after ends_at" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    assign_interview_application(interview_application)
    starts_at = future_quarter_hour(days: 2, hour: 11)
    sign_in_as(candidate)

    assert_no_difference -> { InterviewSchedule.count } do
      post interview_application_interview_schedules_path(interview_application), params: {
        interview_schedule: {
          starts_at: starts_at,
          ends_at: starts_at - 1.hour
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "開始日時は終了日時より前にしてください"
  end

  test "candidate cannot create schedule with invalid timezone" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    assign_interview_application(interview_application)
    starts_at = future_quarter_hour(days: 2)
    sign_in_as(candidate)

    assert_no_difference -> { InterviewSchedule.count } do
      post interview_application_interview_schedules_path(interview_application), params: {
        interview_schedule: {
          starts_at: starts_at,
          ends_at: starts_at + 30.minutes,
          timezone: "Bad/Zone"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "タイムゾーンは不正な値です"
  end

  test "candidate cannot create schedule outside 15 minute increments" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    assign_interview_application(interview_application)
    starts_at = future_quarter_hour(days: 2, min: 10)
    sign_in_as(candidate)

    assert_no_difference -> { InterviewSchedule.count } do
      post interview_application_interview_schedules_path(interview_application), params: {
        interview_schedule: {
          starts_at: starts_at,
          ends_at: starts_at + 30.minutes
        }
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "開始日時は15分単位で指定してください"
    assert_includes response.body, "終了日時は15分単位で指定してください"
  end

  test "capable examiner can approve requested schedule" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    schedule = create_schedule(interview_application)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target)
    sign_in_as(examiner)

    patch approve_interview_schedule_path(schedule)

    assert_redirected_to interview_application_path(interview_application)
    assert schedule.reload.approved?
    assert interview_application.reload.scheduled?
    assert interview_application.exam_application.reload.interview_scheduled?
  end

  test "capable examiner can reject requested schedule" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    schedule = create_schedule(interview_application)
    examiner = create_examiner_for(interview_application.exam_application.evaluation_target)
    sign_in_as(examiner)

    patch reject_interview_schedule_path(schedule)

    assert_redirected_to interview_application_path(interview_application)
    assert schedule.reload.rejected?
    assert interview_application.reload.schedule_requested?
  end

  test "incapable examiner cannot reject requested schedule" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    schedule = create_schedule(interview_application)
    examiner = create_examiner_for(create_evaluation_target)
    sign_in_as(examiner)

    patch reject_interview_schedule_path(schedule)

    assert_response :not_found
    assert schedule.reload.requested?
  end

  test "incapable examiner cannot approve requested schedule" do
    candidate = create_user_with_role(Role::CANDIDATE)
    interview_application = create_interview_application(candidate: candidate)
    schedule = create_schedule(interview_application)
    examiner = create_examiner_for(create_evaluation_target)
    sign_in_as(examiner)

    patch approve_interview_schedule_path(schedule)

    assert_response :not_found
    assert schedule.reload.requested?
  end

  test "dual role candidate examiner cannot approve own schedule" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    interview_application = create_interview_application(candidate: candidate_examiner)
    schedule = create_schedule(interview_application)
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Self Examiner")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: interview_application.exam_application.evaluation_target
    )
    sign_in_as(candidate_examiner)

    patch approve_interview_schedule_path(schedule)

    assert_response :forbidden
    assert schedule.reload.requested?
  end

  test "dual role candidate examiner cannot reject own schedule" do
    candidate_examiner = create_user_with_role(Role::CANDIDATE)
    add_role(candidate_examiner, Role::EXAMINER)
    interview_application = create_interview_application(candidate: candidate_examiner)
    schedule = create_schedule(interview_application)
    profile = ExaminerProfile.create!(user: candidate_examiner, display_name: "Self Examiner")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: interview_application.exam_application.evaluation_target
    )
    sign_in_as(candidate_examiner)

    patch reject_interview_schedule_path(schedule)

    assert_response :forbidden
    assert schedule.reload.requested?
  end

  private

  def create_interview_application(candidate:)
    exam_application = create_review_approved_exam_application(candidate: candidate)
    InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)
  end

  def create_schedule(interview_application)
    assign_interview_application(interview_application)
    starts_at = future_quarter_hour(days: 3)
    InterviewSchedules::CreateService.call(
      interview_application: interview_application,
      actor: interview_application.exam_application.candidate,
      attributes: {
        starts_at: starts_at,
        ends_at: starts_at + 30.minutes
      }
    )
  end

  def future_quarter_hour(days:, hour: 10, min: 0)
    Time.zone.local(Date.current.year, Date.current.month, Date.current.day, hour, min, 0) + days.days
  end

  def assign_interview_application(interview_application)
    return interview_application if interview_application.assigned_examiner_profile.present?

    examiner = create_examiner_for(interview_application.exam_application.evaluation_target)
    InterviewApplications::AssignExaminerService.call(
      interview_application: interview_application,
      actor: examiner,
      examiner_profile: examiner.examiner_profile
    )
  end

  def create_examiner_for(evaluation_target)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: evaluation_target)
    examiner
  end

  def create_declared_exam_application(candidate:)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: create_evaluation_target,
      actor: candidate
    )
  end

  def create_review_approved_exam_application(candidate:)
    create_declared_exam_application(candidate: candidate).tap do |exam_application|
      exam_application.update!(status: :review_approved)
    end
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
