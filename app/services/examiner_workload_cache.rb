class ExaminerWorkloadCache
  Workload = Struct.new(:profile_id, :monthly_interview_count, :max_monthly_interviews, keyword_init: true) do
    def initialize(profile_id:, monthly_interview_count:, max_monthly_interviews:)
      super
      freeze
    end

    def sort_key
      [ monthly_interview_count, profile_id ]
    end
  end

  def initialize
    @mutex = Mutex.new
    @cache = {}
  end

  def fetch(examiner_profile)
    @mutex.synchronize do
      @cache[examiner_profile.id] ||= build_workload(examiner_profile)
    end
  end

  def clear
    @mutex.synchronize { @cache.clear }
  end

  def size
    @mutex.synchronize { @cache.size }
  end

  private

  def build_workload(examiner_profile)
    Workload.new(
      profile_id: examiner_profile.id,
      monthly_interview_count: examiner_profile.monthly_interview_count.to_i,
      max_monthly_interviews: examiner_profile.max_monthly_interviews
    )
  end
end
