module Examiner
  class ReviewQueueController < ApplicationController
    before_action :authenticate_user!

    def index
      authorize ReviewApplication, :queue?
      skip_policy_scope

      reviews = Search::ReviewQueueSearch.new(queue_scope, search_params).relation

      render plain: reviews.map { |review_application| review_line(review_application) }.join("\n")
    end

    private

    def search_params
      params.permit(
        :status,
        :evaluation_target_id,
        :candidate_keyword,
        :keyword,
        :comment_keyword,
        :page,
        :per_page
      )
    end

    def queue_scope
      ReviewApplicationPolicy::QueueScope.new(current_user, ReviewApplication.all).resolve
    end

    def review_line(review_application)
      exam_application = review_application.exam_application
      [
        "review=#{review_application.id}",
        "status=#{review_application.status}",
        "candidate=#{exam_application.candidate.name}<#{exam_application.candidate.email}>",
        "target=#{exam_application.evaluation_target.display_name}",
        "submissions=#{review_application.submissions.size}"
      ].join(" | ")
    end
  end
end
