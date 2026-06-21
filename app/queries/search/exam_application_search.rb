module Search
  class ExamApplicationSearch < BaseSearch
    DEFAULT_EXCLUDED_STATUSES = %w[failed canceled closed].freeze
    DEFAULT_EXCLUDED_RESULTS = %w[failed canceled].freeze

    def relation
      paginate(filtered_scope.recent)
    end

    private

    def filtered_scope
      relation = scope.includes(
        :candidate,
        :evaluation_period,
        evaluation_target: %i[skill_area programming_language framework skill_level]
      )
      relation = apply_status_filter(relation)
      relation = apply_result_filter(relation)
      relation = relation.where(evaluation_target_id: param(:evaluation_target_id)) if param(:evaluation_target_id)
      relation = relation.where(candidate_id: param(:candidate_id)) if param(:candidate_id)
      apply_keyword(relation)
    end

    def apply_status_filter(relation)
      selected_statuses = selected_status_values
      return relation.where(status: selected_statuses) if selected_statuses.any?
      return relation if status_filter_requested?

      relation.where.not(status: ExamApplication.statuses.values_at(*DEFAULT_EXCLUDED_STATUSES))
    end

    def selected_status_values
      values = enum_values(ExamApplication, :status, array_param(:statuses))
      values.presence || Array.wrap(enum_value(ExamApplication, :status, param(:status))).compact
    end

    def status_filter_requested?
      param(:status).present? || array_param(:statuses).any?
    end

    def apply_result_filter(relation)
      return relation.where(result: enum_value(ExamApplication, :result, param(:result))) if param(:result)

      relation.where.not(result: ExamApplication.results.values_at(*DEFAULT_EXCLUDED_RESULTS))
    end

    def apply_keyword(relation)
      return relation if param(:keyword).blank?

      relation.where(evaluation_target_id: matching_target_ids)
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
