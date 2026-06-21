module ReviewComments
  class CreateService
    def self.call(review_application:, examiner:, attributes:)
      new(review_application: review_application, examiner: examiner, attributes: attributes).call
    end

    def initialize(review_application:, examiner:, attributes:)
      @review_application = review_application
      @examiner = examiner
      @attributes = attributes
    end

    def call
      review_application.with_lock do
        raise_not_commentable! unless review_application.commentable?

        review_application.review_comments.create!(comment_attributes.merge(examiner: examiner))
      end
    end

    private

    attr_reader :review_application, :examiner, :attributes

    def comment_attributes
      attributes.slice(:body_markdown)
    end

    def raise_not_commentable!
      review_application.errors.add(:base, "review application does not accept comments")
      raise ActiveRecord::RecordInvalid, review_application
    end
  end
end
