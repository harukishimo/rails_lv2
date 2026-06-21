require "test_helper"

class ReviewDecisionServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "comment creation does not change review status" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)

    comment = ReviewComments::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { body_markdown: "Looks **good**" }
    )

    assert comment.persisted?
    assert_includes comment.rendered_body_html, "<strong>good</strong>"
    assert review_application.reload.submitted?
  end

  test "return decision changes review status but not exam application status" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)

    decision = nil
    assert_enqueued_with(job: SlackDeliveryJob) do
      assert_difference -> { StatusChangeEvent.where(subject: review_application).count }, 1 do
        decision = ReviewDecisions::CreateService.call(
          review_application: review_application,
          examiner: examiner,
          attributes: { decision: "return_to_candidate", reason_markdown: "Please add tests" }
        )
      end
    end

    assert decision.decision_return_to_candidate?
    assert review_application.reload.returned?
    assert review_application.exam_application.reload.reviewing?
    event = StatusChangeEvent.where(subject: review_application).order(:id).last
    assert_equal "review_application_returned", event.event_type
    assert_equal "submitted", event.from_status
    assert_equal "returned", event.to_status
  end

  test "candidate update resubmits returned review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    ReviewDecisions::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { decision: "return_to_candidate", reason_markdown: "Please add tests" }
    )

    ReviewApplications::UpdateService.call(
      review_application: review_application,
      actor: candidate,
      attributes: { appeal_markdown: "updated appeal" }
    )

    assert review_application.reload.submitted?
  end

  test "approve decision updates review and exam application status" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)

    decision = nil
    assert_enqueued_with(job: SlackDeliveryJob) do
      assert_difference -> { StatusChangeEvent.where(subject: review_application).count }, 1 do
        decision = ReviewDecisions::CreateService.call(
          review_application: review_application,
          examiner: examiner,
          attributes: { decision: "approve" }
        )
      end
    end

    assert decision.decision_approve?
    assert review_application.reload.approved?
    assert_equal examiner, review_application.decided_by
    assert_not_nil review_application.decided_at
    assert review_application.exam_application.reload.review_approved?
    event = StatusChangeEvent.where(subject: review_application).order(:id).last
    assert_equal "review_application_approved", event.event_type
    assert_equal "submitted", event.from_status
    assert_equal "approved", event.to_status
  end

  test "reject decision requires reason and finalizes review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      ReviewDecisions::CreateService.call(
        review_application: review_application,
        examiner: examiner,
        attributes: { decision: "reject" }
      )
    end
    assert_includes error.record.errors[:reason_markdown], "can't be blank"

    ReviewDecisions::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { decision: "reject", reason_markdown: "Evidence does not match" }
    )

    assert review_application.reload.rejected?
  end

  test "final review application rejects additional decisions" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    ReviewDecisions::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { decision: "approve" }
    )

    error = assert_raises(ActiveRecord::RecordInvalid) do
      ReviewDecisions::CreateService.call(
        review_application: review_application,
        examiner: examiner,
        attributes: { decision: "reject", reason_markdown: "late reject" }
      )
    end

    assert_includes error.record.errors[:base], "review application does not accept decisions"
  end

  test "canceled review application rejects comment update" do
    candidate = create_user_with_role(Role::CANDIDATE)
    review_application = create_review_application(candidate: candidate)
    examiner = create_examiner_for(review_application.exam_application.evaluation_target)
    comment = ReviewComments::CreateService.call(
      review_application: review_application,
      examiner: examiner,
      attributes: { body_markdown: "first" }
    )
    ReviewApplications::CancelService.call(review_application: review_application, actor: candidate)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      ReviewComments::UpdateService.call(
        review_comment: comment,
        examiner: examiner,
        attributes: { body_markdown: "updated" }
      )
    end

    assert_includes error.record.errors[:review_application], "must accept comments"
  end

  private

  def create_review_application(candidate:)
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
end
