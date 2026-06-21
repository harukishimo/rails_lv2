class ExaminerSuggestionService
  def self.call(interview_application:, limit: 1)
    new(interview_application: interview_application, limit: limit).call
  end

  def initialize(interview_application:, limit: 1)
    @interview_application = interview_application
    @limit = limit
    @workload_cache = ExaminerWorkloadCache.new
  end

  def call
    return candidates.first if limit == 1

    candidates.first(limit)
  end

  def candidates
    candidate_scope.to_a.sort_by { |profile| workload_cache.fetch(profile).sort_key }
  end

  private

  attr_reader :interview_application, :limit, :workload_cache

  def candidate_scope
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
  end

  def evaluation_target
    interview_application.exam_application.evaluation_target
  end
end
