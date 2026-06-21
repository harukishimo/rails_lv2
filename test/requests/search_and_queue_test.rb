require "test_helper"

class SearchAndQueueTest < ActionDispatch::IntegrationTest
  test "evaluation target search uses permitted filters and hides inactive targets from candidates" do
    candidate = create_user_with_role(Role::CANDIDATE, name: "Candidate")
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    inactive_target = create_evaluation_target(language_name: "Rust", framework_name: nil, level_code: "Lv4", active: false)
    sign_in_as(candidate)

    get evaluation_targets_path, params: { keyword: "Ruby", admin: "1" }

    assert_response :success
    assert_includes response.body, ruby_target.programming_language.name
    assert_not_includes response.body, go_target.programming_language.name
    assert_not_includes response.body, inactive_target.programming_language.name
  end

  test "evaluation target search paginates with a capped allowlisted parameter" do
    candidate = create_user_with_role(Role::CANDIDATE, name: "Candidate")
    keyword = "Pagination#{SecureRandom.hex(4)}"
    first_target = create_evaluation_target(
      language_name: "#{keyword} Ruby",
      framework_name: "Rails",
      level_code: "Lv2"
    )
    second_target = create_evaluation_target(
      language_name: "#{keyword} Go",
      framework_name: "Gin",
      level_code: "Lv3"
    )
    sign_in_as(candidate)

    get evaluation_targets_path, params: { keyword: keyword, per_page: 1, page: 1, unsafe_order: "name desc" }

    assert_response :success
    assert_includes response.body, first_target.programming_language.name
    assert_not_includes response.body, second_target.programming_language.name

    get evaluation_targets_path, params: { keyword: keyword, per_page: 1, page: 2 }

    assert_response :success
    assert_includes response.body, second_target.programming_language.name
  end

  test "candidate can search own exam applications by status and target keyword" do
    candidate = create_user_with_role(Role::CANDIDATE, name: "Candidate")
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    ruby_application = create_exam_application(candidate: candidate, target: ruby_target)
    go_application = create_exam_application(candidate: candidate, target: go_target)
    sign_in_as(candidate)

    get exam_applications_path, params: { status: "declared", keyword: "Ruby", admin: "1" }

    assert_response :success
    assert_includes response.body, "受験ID: #{ruby_application.id}"
    assert_not_includes response.body, "受験ID: #{go_application.id}"
  end

  test "examiner review queue only shows review applications for reviewable targets" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    ruby_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE, name: "Ruby Candidate"), target: ruby_target)
    go_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE, name: "Go Candidate"), target: go_target)
    examiner = create_examiner_for(ruby_target)
    sign_in_as(examiner)

    get examiner_review_queue_index_path, params: { statuses: %w[submitted], keyword: "Ruby" }

    assert_response :success
    assert_includes response.body, ruby_review.exam_application.candidate.name
    assert_not_includes response.body, go_review.exam_application.candidate.name
  end

  test "examiner review queue excludes candidate draft reviews" do
    target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    draft_review = create_draft_review_application(candidate: create_user_with_role(Role::CANDIDATE), target: target)
    examiner = create_examiner_for(target)
    sign_in_as(examiner)

    get examiner_review_queue_index_path

    assert_response :success
    assert_not_includes response.body, draft_review.exam_application.candidate.email
  end

  test "examiner review queue excludes active but not reviewable capabilities" do
    target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    review_application = create_review_application(candidate: create_user_with_role(Role::CANDIDATE), target: target)
    examiner = create_examiner_for(target, can_review: false)
    sign_in_as(examiner)

    get examiner_review_queue_index_path

    assert_response :success
    assert_not_includes response.body, review_application.exam_application.candidate.email
  end

  test "examiner review queue does not mix candidate-owned reviews for hybrid users" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    hybrid_user = create_user_with_role(Role::CANDIDATE, name: "Hybrid User")
    add_role(hybrid_user, Role::EXAMINER)
    profile = ExaminerProfile.create!(user: hybrid_user, display_name: "Hybrid #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(examiner_profile: profile, evaluation_target: ruby_target, can_review: true)
    visible_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE), target: ruby_target)
    own_non_capable_review = create_review_application(candidate: hybrid_user, target: go_target)
    own_capable_review = create_review_application(candidate: hybrid_user, target: ruby_target)
    sign_in_as(hybrid_user)

    get examiner_review_queue_index_path

    assert_response :success
    assert_includes response.body, visible_review.exam_application.candidate.name
    assert_not_includes response.body, own_non_capable_review.exam_application.candidate.email
    assert_not_includes response.body, own_capable_review.exam_application.candidate.email
  end

  test "review queue searches review comment body with explicit comment keyword" do
    target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    examiner = create_examiner_for(target)
    matching_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE, name: "Migration Candidate"), target: target)
    other_review = create_review_application(candidate: create_user_with_role(Role::CANDIDATE, name: "Plain Candidate"), target: target)
    ReviewComment.create!(
      review_application: matching_review,
      examiner: examiner,
      body_markdown: "needs migration evidence"
    )
    ReviewComment.create!(
      review_application: other_review,
      examiner: examiner,
      body_markdown: "looks fine"
    )
    sign_in_as(examiner)

    get examiner_review_queue_index_path, params: { comment_keyword: "migration evidence" }

    assert_response :success
    assert_includes response.body, matching_review.exam_application.candidate.name
    assert_not_includes response.body, other_review.exam_application.candidate.name
  end

  test "candidate cannot open examiner review queue" do
    candidate = create_user_with_role(Role::CANDIDATE)
    sign_in_as(candidate)

    get examiner_review_queue_index_path

    assert_response :forbidden
  end

  test "examiner interview queue shows interviewable pending applications and supports multiple status filters" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    pending_interview = create_interview_application(
      candidate: create_user_with_role(Role::CANDIDATE, name: "Pending Candidate"),
      target: ruby_target
    )
    hidden_interview = create_interview_application(
      candidate: create_user_with_role(Role::CANDIDATE, name: "Hidden Candidate"),
      target: go_target
    )
    completed_interview = create_interview_application(
      candidate: create_user_with_role(Role::CANDIDATE, name: "Completed Candidate"),
      target: ruby_target
    )
    completed_interview.update!(status: :completed)
    examiner = create_examiner_for(ruby_target, can_review: false, can_interview: true)
    sign_in_as(examiner)

    get examiner_interview_queue_index_path

    assert_response :success
    assert_includes response.body, pending_interview.exam_application.candidate.name
    assert_not_includes response.body, hidden_interview.exam_application.candidate.name
    assert_not_includes response.body, completed_interview.exam_application.candidate.name

    get examiner_interview_queue_index_path, params: { statuses: %w[completed requested] }

    assert_response :success
    assert_includes response.body, pending_interview.exam_application.candidate.name
    assert_includes response.body, completed_interview.exam_application.candidate.name
    assert_not_includes response.body, hidden_interview.exam_application.candidate.name
  end

  test "examiner can search candidates and see visible candidate qualifications" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    ruby_candidate = create_user_with_role(Role::CANDIDATE, name: "Ruby Candidate", email: "ruby-candidate@example.com")
    go_candidate = create_user_with_role(Role::CANDIDATE, name: "Go Candidate", email: "go-candidate@example.com")
    closed_candidate = create_user_with_role(Role::CANDIDATE, name: "Closed Candidate", email: "closed-candidate@example.com")
    ruby_application = create_exam_application(candidate: ruby_candidate, target: ruby_target)
    hidden_application = create_exam_application(candidate: ruby_candidate, target: go_target)
    create_exam_application(candidate: go_candidate, target: go_target)
    closed_application = create_exam_application(candidate: closed_candidate, target: ruby_target)
    ExamApplications::TransitionService.new(closed_application, actor: closed_candidate).close!
    examiner = create_examiner_for(ruby_target)
    qualification = create_user_qualification(
      user: ruby_candidate,
      target: ruby_target,
      exam_application: ruby_application,
      granted_by: examiner
    )
    hidden_qualification = create_user_qualification(
      user: ruby_candidate,
      target: go_target,
      exam_application: hidden_application,
      granted_by: create_examiner_for(go_target)
    )
    sign_in_as(examiner)

    get examiner_candidates_path, params: { keyword: "Ruby" }

    assert_response :success
    assert_includes response.body, ruby_candidate.email
    assert_not_includes response.body, go_candidate.email
    assert_not_includes response.body, closed_candidate.email

    get examiner_candidates_path, params: { evaluation_target_id: go_target.id }

    assert_response :success
    assert_not_includes response.body, ruby_candidate.email

    get examiner_candidates_path, params: { statuses: %w[declared] }

    assert_response :success
    assert_includes response.body, ruby_candidate.email
    assert_not_includes response.body, closed_candidate.email

    get examiner_candidate_path(ruby_candidate)

    assert_response :success
    assert_includes response.body, qualification.evaluation_target.programming_language.name
    assert_includes response.body, ruby_target.skill_level.code
    assert_not_includes response.body, hidden_qualification.evaluation_target.programming_language.name
    assert_not_includes response.body, hidden_application.evaluation_target.programming_language.name

    get examiner_candidate_path(go_candidate)

    assert_response :not_found
  end

  test "user qualification index is scoped to current user or examiner capabilities" do
    ruby_target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    go_target = create_evaluation_target(language_name: "Go", framework_name: "Gin", level_code: "Lv3")
    ruby_candidate = create_user_with_role(Role::CANDIDATE, name: "Ruby Candidate", email: "ruby-qualified@example.com")
    go_candidate = create_user_with_role(Role::CANDIDATE, name: "Go Candidate", email: "go-qualified@example.com")
    ruby_examiner = create_examiner_for(ruby_target)
    go_examiner = create_examiner_for(go_target)
    ruby_qualification = create_user_qualification(
      user: ruby_candidate,
      target: ruby_target,
      exam_application: create_exam_application(candidate: ruby_candidate, target: ruby_target),
      granted_by: ruby_examiner
    )
    go_qualification = create_user_qualification(
      user: go_candidate,
      target: go_target,
      exam_application: create_exam_application(candidate: go_candidate, target: go_target),
      granted_by: go_examiner
    )
    revoked_target = create_evaluation_target(language_name: "Python", framework_name: "Django", level_code: "Lv4")
    revoked_qualification = create_user_qualification(
      user: ruby_candidate,
      target: revoked_target,
      exam_application: create_exam_application(
        candidate: ruby_candidate,
        target: revoked_target
      ),
      granted_by: ruby_examiner
    )
    revoked_qualification.update!(revoked_at: Time.current)

    sign_in_as(ruby_candidate)
    get user_qualifications_path

    assert_response :success
    assert_includes response.body, ruby_qualification.evaluation_target.programming_language.name
    assert_not_includes response.body, go_qualification.evaluation_target.programming_language.name
    assert_not_includes response.body, revoked_qualification.evaluation_target.programming_language.name

    delete destroy_user_session_path
    sign_in_as(ruby_examiner)
    get user_qualifications_path, params: { user_keyword: "qualified" }

    assert_response :success
    assert_includes response.body, ruby_qualification.user.email
    assert_not_includes response.body, go_qualification.user.email
  end

  test "review queue list preloads associations used for rendering" do
    target = create_evaluation_target(language_name: "Ruby", framework_name: "Rails", level_code: "Lv2")
    examiner = create_examiner_for(target)
    create_review_application(candidate: create_user_with_role(Role::CANDIDATE, name: "Candidate 1"), target: target)
    sign_in_as(examiner)

    one_result_query_count = count_select_queries do
      get examiner_review_queue_index_path
      assert_response :success
    end

    2.times do |index|
      create_review_application(candidate: create_user_with_role(Role::CANDIDATE, name: "Candidate #{index + 2}"), target: target)
    end

    many_result_query_count = count_select_queries do
      get examiner_review_queue_index_path
      assert_response :success
    end

    assert_operator many_result_query_count, :<=, one_result_query_count + 3
  end

  private

  def create_review_application(candidate:, target:)
    exam_application = create_exam_application(candidate: candidate, target: target)
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

  def create_draft_review_application(candidate:, target:)
    exam_application = create_exam_application(candidate: candidate, target: target)
    ReviewApplication.create!(
      exam_application: exam_application,
      sequence_number: 1,
      status: :draft,
      appeal_markdown: "draft appeal"
    )
  end

  def create_interview_application(candidate:, target:)
    exam_application = create_exam_application(candidate: candidate, target: target)
    exam_application.update!(status: :review_approved)
    InterviewApplications::CreateService.call(exam_application: exam_application, actor: candidate)
  end

  def create_exam_application(candidate:, target:)
    ExamApplications::CreateService.call(
      candidate: candidate,
      evaluation_period: create_evaluation_period,
      evaluation_target: target,
      actor: candidate
    )
  end

  def create_user_qualification(user:, target:, exam_application:, granted_by:)
    UserQualification.create!(
      user: user,
      evaluation_target: target,
      exam_application: exam_application,
      acquired_on: Date.current,
      granted_by: granted_by
    )
  end

  def create_examiner_for(target, can_review: true, can_interview: true)
    examiner = create_user_with_role(Role::EXAMINER, name: "Examiner")
    profile = ExaminerProfile.create!(user: examiner, display_name: "Examiner #{SecureRandom.hex(4)}")
    ExaminerSkillCapability.create!(
      examiner_profile: profile,
      evaluation_target: target,
      can_review: can_review,
      can_interview: can_interview
    )
    examiner
  end

  def create_evaluation_period
    EvaluationPeriod.create!(
      name: "Period #{SecureRandom.hex(4)}",
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year
    )
  end

  def create_evaluation_target(language_name:, framework_name:, level_code:, active: true)
    language = ProgrammingLanguage.create!(name: "#{language_name} #{SecureRandom.hex(4)}")
    framework = if framework_name
      Framework.create!(name: "#{framework_name} #{SecureRandom.hex(4)}", programming_language: language)
    end
    skill_level = SkillLevel.create!(code: "#{level_code}-#{SecureRandom.hex(4)}", numeric_level: level_code.delete("^0-9").to_i)

    EvaluationTarget.create!(
      skill_area: SkillArea.create!(name: "Backend #{SecureRandom.hex(4)}"),
      programming_language: language,
      framework: framework,
      skill_level: skill_level,
      external_knowledge_key: "#{language_name.downcase}_#{level_code.downcase}_#{SecureRandom.hex(4)}",
      version: "2026.06-#{SecureRandom.hex(4)}",
      active: active
    )
  end

  def create_user_with_role(code, name: "User", email: nil)
    role = Role.find_or_create_by!(code: code) do |record|
      record.name = Role::NAMES.fetch(code)
    end
    user = User.create!(
      name: name,
      email: email || "user-#{SecureRandom.hex(4)}@example.com",
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

  def count_select_queries
    count = 0
    callback = lambda do |_name, _started, _finished, _unique_id, payload|
      next if payload[:cached]
      next if payload[:name].in?(%w[SCHEMA TRANSACTION])
      next unless payload[:sql].match?(/\ASELECT/i)

      count += 1
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      yield
    end
    count
  end
end
