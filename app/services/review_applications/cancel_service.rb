module ReviewApplications
  class CancelService
    def self.call(review_application:, actor:, cancel_reason: nil)
      new(review_application: review_application, actor: actor, cancel_reason: cancel_reason).call
    end

    def initialize(review_application:, actor:, cancel_reason: nil)
      @review_application = review_application
      @actor = actor
      @cancel_reason = cancel_reason
    end

    def call
      review_application.with_lock do
        raise_not_cancelable! unless review_application.cancelable?

        review_application.update!(
          status: :canceled,
          canceled_at: Time.current,
          cancel_reason: cancel_reason
        )
        review_application
      end
    end

    private

    attr_reader :review_application, :actor, :cancel_reason

    def raise_not_cancelable!
      review_application.errors.add(:base, "review application is not cancelable")
      raise ActiveRecord::RecordInvalid, review_application
    end
  end
end
