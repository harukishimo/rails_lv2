module Search
  class ReviewQueueSearch < BaseSearch
    DEFAULT_EXCLUDED_STATUSES = %w[approved rejected canceled].freeze

    def relation
      paginate(filtered_scope.recent)
    end

    private

    def filtered_scope
      relation = scope.includes(
        :submissions,
        :review_comments,
        :review_decisions,
        exam_application: [
          :candidate,
          :evaluation_period,
          { evaluation_target: %i[skill_area programming_language framework skill_level] }
        ]
      )
      relation = apply_status_filter(relation)
      relation = relation.joins(:exam_application).where(exam_applications: { evaluation_target_id: param(:evaluation_target_id) }) if param(:evaluation_target_id)
      relation = relation.joins(:exam_application).where(exam_applications: { candidate_id: matching_candidate_ids }) if param(:candidate_keyword)
      relation = relation.joins(:exam_application).where(exam_applications: { evaluation_target_id: matching_target_ids }) if param(:keyword)
      relation = relation.joins(:review_comments).where("review_comments.body_markdown LIKE ?", escaped_like(param(:comment_keyword))).distinct if param(:comment_keyword)
      relation
    end

    def apply_status_filter(relation)
      selected_statuses = selected_status_values
      return relation.where(status: selected_statuses) if selected_statuses.any?
      return relation if status_filter_requested?

      relation.where.not(status: ReviewApplication.statuses.values_at(*DEFAULT_EXCLUDED_STATUSES))
    end

    def selected_status_values
      values = enum_values(ReviewApplication, :status, array_param(:statuses))
      values.presence || Array.wrap(enum_value(ReviewApplication, :status, param(:status))).compact
    end

    def status_filter_requested?
      param(:status).present? || array_param(:statuses).any?
    end

    def matching_candidate_ids
      User.where("name LIKE :q OR email LIKE :q", q: escaped_like(param(:candidate_keyword))).select(:id)
    end

    def matching_target_ids
      EvaluationTarget.left_joins(:skill_area, :programming_language, :framework, :skill_level)
                      .where(target_keyword_condition, q: escaped_like(param(:keyword)))
                      .select(:id)
    end

    def target_keyword_condition
      [
        "skill_areas.name LIKE :q",
        "programming_languages.name LIKE :q",
        "frameworks.name LIKE :q",
        "skill_levels.code LIKE :q",
        "evaluation_targets.version LIKE :q"
      ].join(" OR ")
    end
  end
end
