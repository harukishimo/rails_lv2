require "test_helper"

class NotificationsTest < ActionDispatch::IntegrationTest
  test "candidate sees own status change events from notifications page" do
    candidate = create_user_with_role(Role::CANDIDATE)
    other_candidate = create_user_with_role(Role::CANDIDATE)
    own_application = create_exam_application(candidate: candidate)
    other_application = create_exam_application(candidate: other_candidate)
    create_status_event(subject: own_application, actor: candidate, message: "own application changed")
    create_status_event(subject: other_application, actor: other_candidate, message: "other application changed")

    sign_in_as(candidate)
    get notifications_path

    assert_response :success
    assert_includes response.body, "通知"
    assert_includes response.body, "レビュー中"
    assert_includes response.body, "受験を受験表明済みからレビュー中へ変更しました"
    assert_not_includes response.body, "own application changed"
    assert_not_includes response.body, "other application changed"
  end

  test "exam application closed event type is localized on notifications page" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_exam_application(candidate: candidate)
    StatusChangeEvent.create!(
      subject: exam_application,
      actor: candidate,
      from_status: "passed",
      to_status: "closed",
      event_type: "exam_application_closed",
      message: "Exam application status changed from passed to closed",
      target_path: "/exam_applications/#{exam_application.id}",
      metadata: {}
    )

    sign_in_as(candidate)
    get notifications_path

    assert_response :success
    assert_includes response.body, "受験クローズ"
    assert_not_includes response.body, "Exam application closed"
  end

  test "examiner sees status changes for capable evaluation targets" do
    candidate = create_user_with_role(Role::CANDIDATE)
    visible_target = create_evaluation_target
    hidden_target = create_evaluation_target
    examiner = create_examiner_for(visible_target)
    visible_application = create_exam_application(candidate: candidate, evaluation_target: visible_target)
    hidden_application = create_exam_application(candidate: candidate, evaluation_target: hidden_target)
    create_status_event(subject: visible_application, actor: candidate, message: "visible target changed")
    create_status_event(subject: hidden_application, actor: candidate, message: "hidden target changed")

    sign_in_as(examiner)
    get notifications_path

    assert_response :success
    assert_includes response.body, "受験を受験表明済みからレビュー中へ変更しました"
    assert_not_includes response.body, "hidden target changed"
  end

  test "interview confirmed notification uses screen message instead of slack payload text" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_exam_application(candidate: candidate)
    exam_application.update!(status: :review_approved)
    interview_application = InterviewApplications::CreateService.call(
      exam_application: exam_application,
      actor: candidate
    )
    StatusChangeEvent.create!(
      subject: interview_application,
      actor: candidate,
      from_status: nil,
      to_status: "interview_confirmed",
      event_type: "interview_confirmed",
      message: "面談が確定しました！\n受験者：佐藤 候補\n言語：Rails\nlv : 2\n試験官: 試験官1、試験官2",
      target_path: "/interview_applications/#{interview_application.id}",
      metadata: {}
    )

    sign_in_as(candidate)
    get notifications_path

    assert_response :success
    assert_includes response.body, "面談確定"
    assert_includes response.body, "面談応募が面談確定になりました"
    assert_not_includes response.body, "受験者：佐藤 候補"
    assert_not_includes response.body, "試験官1、試験官2"
  end

  private

  def create_status_event(subject:, actor:, message:)
    StatusChangeEvent.create!(
      subject: subject,
      actor: actor,
      from_status: "declared",
      to_status: "reviewing",
      event_type: "exam_application_reviewing",
      message: message,
      target_path: "/exam_applications/#{subject.id}",
      metadata: {}
    )
  end

  def create_exam_application(candidate:, evaluation_target: create_evaluation_target)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: evaluation_target,
      actor: candidate
    )
  end

  def create_examiner_for(evaluation_target)
    examiner = create_user_with_role(Role::EXAMINER)
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
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

  def sign_in_as(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
