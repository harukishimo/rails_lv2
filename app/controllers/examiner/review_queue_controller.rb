module Examiner
  class ReviewQueueController < ApplicationController
    before_action :authenticate_user!

    def index
      authorize ReviewApplication, :queue?
      skip_policy_scope

      @review_applications = Search::ReviewQueueSearch.new(queue_scope, search_params).relation
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
  end
end
