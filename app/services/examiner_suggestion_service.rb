class ExaminerSuggestionService
  def self.call(interview_application:)
    new(interview_application: interview_application).call
  end

  def initialize(interview_application:)
    @interview_application = interview_application
  end

  def call
    candidates.first
  end

  def candidates
    ExaminerProfile.available_for_interviews
                   .joins(:examiner_skill_capabilities)
                   .where.not(user_id: interview_application.exam_application.candidate_id)
                   .where(
                     examiner_skill_capabilities: {
                       evaluation_target_id: evaluation_target.id,
                       active: true,
                       can_interview: true,
                       deleted_at: nil
                     }
                   )
                   .where("max_monthly_interviews IS NULL OR monthly_interview_count < max_monthly_interviews")
                   .distinct
                   .order(:monthly_interview_count, :id)
  end

  private

  attr_reader :interview_application

  def evaluation_target
    interview_application.exam_application.evaluation_target
  end
end
