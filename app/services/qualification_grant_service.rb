class QualificationGrantService
  class QualificationGrantError < StandardError; end

  def self.call(interview_application:, examiner:, attributes:)
    new(interview_application: interview_application, examiner: examiner, attributes: attributes).call
  end

  def initialize(interview_application:, examiner:, attributes:)
    @interview_application = interview_application
    @examiner = examiner
    @attributes = attributes
  end

  def call
    InterviewResult.transaction do
      interview_application.with_lock do
        exam_application.with_lock do
          raise_not_decidable! unless interview_application.result_decidable?

          result = create_interview_result!
          apply_exam_result!(result)
          complete_interview!
          result
        end
      end
    end
  end

  private

  attr_reader :interview_application, :examiner, :attributes

  def exam_application
    @exam_application ||= interview_application.exam_application
  end

  def create_interview_result!
    InterviewResult.create!(
      interview_application: interview_application,
      examiner: examiner,
      result: result_value,
      comment_markdown: attributes[:comment_markdown],
      decided_at: Time.current
    )
  end

  def apply_exam_result!(result)
    result.passed? ? grant_qualification! : fail_exam_application!
  end

  def grant_qualification!
    transition_exam_application.mark_passed!
    create_or_update_qualification!
    transition_exam_application.close!
  end

  def fail_exam_application!
    transition_exam_application.mark_failed!
    transition_exam_application.close!
  end

  def create_or_update_qualification!
    qualification = UserQualification.active.find_or_initialize_by(
      user: exam_application.candidate,
      evaluation_target: exam_application.evaluation_target
    )
    qualification.update!(
      exam_application: exam_application,
      acquired_on: Date.current,
      granted_by: examiner
    )
    qualification
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => error
    raise QualificationGrantError, error.message
  end

  def complete_interview!
    InterviewApplications::TransitionService.new(interview_application, actor: examiner).complete!
  end

  def transition_exam_application
    @transition_exam_application ||= ExamApplications::TransitionService.new(exam_application, actor: examiner)
  end

  def result_value
    attributes[:result]
  end

  def raise_not_decidable!
    interview_application.errors.add(:base, "interview application does not accept result")
    raise ActiveRecord::RecordInvalid, interview_application
  end
end
