require "test_helper"

class ReviewApplicationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  teardown do
    clear_enqueued_jobs
    clear_performed_jobs
  end

  test "creates submitted review application with sanitized markdown" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)

    review_application = nil
    assert_no_enqueued_jobs only: SlackDeliveryJob do
      assert_difference -> { StatusChangeEvent.where(subject_type: "ReviewApplication").count }, 1 do
        review_application = ReviewApplications::CreateService.call(
          exam_application: exam_application,
          actor: candidate,
          attributes: {
            appeal_markdown: "**strong** [bad](javascript:alert(1)) <script>alert(1)</script>",
            submissions_attributes: [
              {
                kind: "github_repository",
                title: "Rails app repository",
                github_url: "https://github.com/harukishimo/rails_lv2"
              }
            ]
          }
        )
      end
    end

    assert review_application.submitted?
    assert_equal 1, review_application.sequence_number
    assert_equal "**strong** [bad](javascript:alert(1)) <script>alert(1)</script>",
                 review_application.appeal_markdown
    assert_includes review_application.rendered_appeal_html, "<strong>strong</strong>"
    assert_no_match(/javascript:/, review_application.rendered_appeal_html)
    assert_no_match(/<script/, review_application.rendered_appeal_html)
    assert_equal 1, review_application.submissions.size
    assert exam_application.reload.reviewing?
    event = StatusChangeEvent.where(subject: review_application).order(:id).last
    assert_equal "review_application_submitted", event.event_type
    assert_nil event.from_status
    assert_equal "submitted", event.to_status
  end

  test "requires exam application" do
    review_application = ReviewApplication.new(sequence_number: 1, status: :submitted, submitted_at: Time.current)

    assert_not review_application.valid?
    assert_includes review_application.errors[:exam_application], "must exist"
  end

  test "submitted review application requires evidence submission" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)

    review_application = ReviewApplication.new(
      exam_application: exam_application,
      sequence_number: 1,
      status: :submitted,
      submitted_at: Time.current,
      appeal_markdown: "appeal"
    )

    assert_not review_application.valid?
    assert_includes review_application.errors[:base], "review application must include a file or GitHub repository submission"
  end

  test "submitted review application does not treat supplement as evidence" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)

    review_application = ReviewApplication.new(
      exam_application: exam_application,
      sequence_number: 1,
      status: :submitted,
      submitted_at: Time.current,
      appeal_markdown: "appeal",
      submissions_attributes: [
        {
          kind: "supplement",
          title: "Supplement note",
          note: "not primary evidence"
        }
      ]
    )

    assert_not review_application.valid?
    assert_includes review_application.errors[:base], "review application must include a file or GitHub repository submission"
  end

  test "appeal markdown length is limited to detailed design maximum" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)

    review_application = ReviewApplication.new(
      exam_application: exam_application,
      sequence_number: 1,
      status: :submitted,
      submitted_at: Time.current,
      appeal_markdown: "a" * 10_001,
      submissions_attributes: [
        {
          kind: "github_repository",
          title: "Repository",
          github_url: "https://github.com/harukishimo/rails_lv2"
        }
      ]
    )

    assert_not review_application.valid?
    assert_includes review_application.errors[:appeal_markdown], "is too long (maximum is 10000 characters)"
  end

  test "prevents duplicate in-progress review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    create_review_application(candidate: candidate, exam_application: exam_application)

    duplicate = ReviewApplication.new(
      exam_application: exam_application,
      sequence_number: 2,
      status: :submitted,
      submitted_at: Time.current
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "in-progress review application already exists"
  end

  test "database rejects duplicate in-progress review application" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    create_review_application(candidate: candidate, exam_application: exam_application)

    error = assert_raises(ActiveRecord::RecordNotUnique) do
      ReviewApplication.insert_all!([
        insert_review_attributes_for(exam_application: exam_application, sequence_number: 2, status: :submitted)
      ])
    end

    assert_match(/review_applications.exam_application_id/, error.message)
  end

  test "can create next review application after cancellation" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    review_application = create_review_application(candidate: candidate, exam_application: exam_application)

    ReviewApplications::CancelService.call(review_application: review_application, actor: candidate)

    next_review = create_review_application(candidate: candidate, exam_application: exam_application)

    assert_equal 2, next_review.sequence_number
    assert next_review.submitted?
  end

  test "does not restore in-progress review when another one exists" do
    candidate = create_user_with_role(Role::CANDIDATE)
    exam_application = create_declared_exam_application(candidate: candidate)
    deleted_review = create_review_application_without_submission(exam_application: exam_application, sequence_number: 1)
    deleted_review.destroy
    create_review_application_without_submission(exam_application: exam_application, sequence_number: 2)

    assert_no_difference -> { ReviewApplication.where(exam_application: exam_application).count } do
      deleted_review.restore(recursive: false)
    end
    assert deleted_review.reload.deleted?
    assert_includes deleted_review.errors[:base], "cannot restore because in-progress review application already exists"
  end

  private

  def create_review_application(candidate:, exam_application:)
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

  def create_review_application_without_submission(exam_application:, sequence_number:)
    ReviewApplication.create!(
      exam_application: exam_application,
      sequence_number: sequence_number,
      status: :draft,
      appeal_markdown: "appeal"
    )
  end

  def insert_review_attributes_for(exam_application:, sequence_number:, status:)
    now = Time.current

    {
      exam_application_id: exam_application.id,
      sequence_number: sequence_number,
      status: ReviewApplication.statuses.fetch(status.to_s),
      appeal_markdown: "appeal",
      rendered_appeal_html: "<p>appeal</p>",
      submitted_at: now,
      lock_version: 0,
      created_at: now,
      updated_at: now
    }
  end

  def create_declared_exam_application(candidate:)
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
