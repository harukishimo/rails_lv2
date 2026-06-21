class ReviewDecisionPolicy < ApplicationPolicy
  def create?
    ReviewApplicationPolicy.new(user, record.review_application).decide?
  end
end
