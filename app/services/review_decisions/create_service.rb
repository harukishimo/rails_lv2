module ReviewDecisions
  class CreateService
    STATUS_BY_DECISION = {
      "return_to_candidate" => "returned",
      "approve" => "approved",
      "reject" => "rejected"
    }.freeze

    def self.call(review_application:, examiner:, attributes:)
      new(review_application: review_application, examiner: examiner, attributes: attributes).call
    end

    def initialize(review_application:, examiner:, attributes:)
      @review_application = review_application
      @examiner = examiner
      @attributes = attributes
    end

    def call
      ReviewDecision.transaction do
        review_application.with_lock do
          raise_not_decidable! unless review_application.decidable?

          decision = review_application.review_decisions.create!(decision_attributes.merge(examiner: examiner))
          apply_decision!(decision)
          decision
        end
      end
    end

    private

    attr_reader :review_application, :examiner, :attributes

    def decision_attributes
      attributes.slice(:decision, :reason_markdown)
    end

    def apply_decision!(decision)
      next_status = STATUS_BY_DECISION.fetch(decision.decision)
      previous_status = review_application.status
      update_attributes = { status: next_status }
      update_attributes.merge!(decided_by: examiner, decided_at: decision.decided_at) if decision.decision_approve? || decision.decision_reject?

      review_application.update!(update_attributes)
      ReviewApplications::StatusChangeRecorder.call(
        review_application: review_application,
        actor: examiner,
        previous_status: previous_status,
        next_status: next_status
      )
      approve_exam_application! if decision.decision_approve?
    end

    def approve_exam_application!
      return unless review_application.exam_application.reviewing?

      ExamApplications::TransitionService.new(review_application.exam_application, actor: examiner).approve_review!
    end

    def raise_not_decidable!
      review_application.errors.add(:base, :review_application_does_not_accept_decisions)
      raise ActiveRecord::RecordInvalid, review_application
    end
  end
end
