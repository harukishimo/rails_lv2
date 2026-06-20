module Search
  class EvaluationTargetSearch < BaseSearch
    def relation
      paginate(filtered_scope.ordered)
    end

    private

    def filtered_scope
      relation = scope.includes(:skill_area, :programming_language, :framework, :skill_level)
      relation = relation.where(skill_area_id: param(:skill_area_id)) if param(:skill_area_id)
      relation = relation.where(programming_language_id: param(:programming_language_id)) if param(:programming_language_id)
      relation = relation.where(framework_id: param(:framework_id)) if param(:framework_id)
      relation = relation.where(skill_level_id: param(:skill_level_id)) if param(:skill_level_id)
      relation = relation.where(active: boolean_param(:active)) unless boolean_param(:active).nil?
      apply_keyword(relation)
    end

    def apply_keyword(relation)
      return relation if param(:keyword).blank?

      target_ids = EvaluationTarget.left_joins(:skill_area, :programming_language, :framework, :skill_level)
                                   .where(keyword_condition, q: escaped_like(param(:keyword)))
                                   .select(:id)
      relation.where(id: target_ids)
    end

    def keyword_condition
      [
        "skill_areas.name LIKE :q",
        "programming_languages.name LIKE :q",
        "frameworks.name LIKE :q",
        "skill_levels.code LIKE :q",
        "evaluation_targets.version LIKE :q",
        "evaluation_targets.external_knowledge_key LIKE :q"
      ].join(" OR ")
    end

    def boolean_param(key)
      return nil unless params.key?(key)

      ActiveModel::Type::Boolean.new.cast(params[key])
    end
  end
end
