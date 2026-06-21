module ReviewApplications
  class UpdateService
    def self.call(review_application:, actor:, attributes:)
      new(review_application: review_application, actor: actor, attributes: attributes).call
    end

    def initialize(review_application:, actor:, attributes:)
      @review_application = review_application
      @actor = actor
      @attributes = attributes
    end

    def call
      review_application.with_lock do
        raise_not_editable! unless review_application.editable?

        review_application.update!(review_attributes.merge(resubmission_attributes))
        review_application
      end
    end

    private

    attr_reader :review_application, :actor, :attributes

    def review_attributes
      attributes.slice(:appeal_markdown, :submissions_attributes)
    end

    def resubmission_attributes
      return {} unless review_application.returned?

      {
        status: :submitted,
        submitted_at: Time.current
      }
    end

    def raise_not_editable!
      review_application.errors.add(:base, "review application is not editable")
      raise ActiveRecord::RecordInvalid, review_application
    end
  end
end
