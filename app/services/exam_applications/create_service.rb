module ExamApplications
  class CreateService
    def self.call(candidate:, evaluation_period:, evaluation_target:, actor:)
      new(
        candidate: candidate,
        evaluation_period: evaluation_period,
        evaluation_target: evaluation_target,
        actor: actor
      ).call
    end

    def initialize(candidate:, evaluation_period:, evaluation_target:, actor:)
      @candidate = candidate
      @evaluation_period = evaluation_period
      @evaluation_target = evaluation_target
      @actor = actor
    end

    def call
      ExamApplication.transaction do
        candidate.with_lock do
          application = ExamApplication.create!(
            candidate: candidate,
            evaluation_period: evaluation_period,
            evaluation_target: evaluation_target,
            attempt_number: next_attempt_number,
            status: :draft,
            result: :none
          )

          TransitionService.new(application, actor: actor).declare!
          application
        end
      end
    end

    private

    attr_reader :candidate, :evaluation_period, :evaluation_target, :actor

    def next_attempt_number
      ExamApplication.with_deleted.where(
        candidate: candidate,
        evaluation_period: evaluation_period,
        evaluation_target: evaluation_target
      ).maximum(:attempt_number).to_i + 1
    end
  end
end
