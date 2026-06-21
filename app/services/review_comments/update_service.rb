module ReviewComments
  class UpdateService
    def self.call(review_comment:, examiner:, attributes:)
      new(review_comment: review_comment, examiner: examiner, attributes: attributes).call
    end

    def initialize(review_comment:, examiner:, attributes:)
      @review_comment = review_comment
      @examiner = examiner
      @attributes = attributes
    end

    def call
      review_comment.review_application.with_lock do
        raise_not_commentable! unless review_comment.review_application.commentable?

        review_comment.update!(comment_attributes)
        review_comment
      end
    end

    private

    attr_reader :review_comment, :examiner, :attributes

    def comment_attributes
      attributes.slice(:body_markdown)
    end

    def raise_not_commentable!
      review_comment.errors.add(:review_application, :must_accept_comments)
      raise ActiveRecord::RecordInvalid, review_comment
    end
  end
end
