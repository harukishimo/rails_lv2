module Search
  class ExamApplicationSearch < BaseSearch
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
      relation = relation.where(status: enum_value(ExamApplication, :status, param(:status))) if param(:status)
      relation = relation.where(result: enum_value(ExamApplication, :result, param(:result))) if param(:result)
      relation = relation.where(evaluation_target_id: param(:evaluation_target_id)) if param(:evaluation_target_id)
      relation = relation.where(candidate_id: param(:candidate_id)) if param(:candidate_id)
      apply_keyword(relation)
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
