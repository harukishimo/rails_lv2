module Examiner
  class InterviewQueueController < ApplicationController
    before_action :authenticate_user!

    def index
      authorize InterviewApplication, :queue?
      skip_policy_scope

      @interview_applications = Search::InterviewQueueSearch.new(queue_scope, search_params).relation
    end

    private

    def search_params
      params.permit(
        :status,
        :evaluation_target_id,
        :candidate_keyword,
        :keyword,
        :page,
        :per_page,
        statuses: []
      )
    end

    def queue_scope
      InterviewApplicationPolicy::QueueScope.new(current_user, InterviewApplication.all).resolve
    end
  end
end
