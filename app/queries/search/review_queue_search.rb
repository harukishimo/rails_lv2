module Search
  class ReviewQueueSearch < BaseSearch
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
      relation = relation.where(status: enum_value(ReviewApplication, :status, param(:status))) if param(:status)
      relation = relation.joins(:exam_application).where(exam_applications: { evaluation_target_id: param(:evaluation_target_id) }) if param(:evaluation_target_id)
      relation = relation.joins(:exam_application).where(exam_applications: { candidate_id: matching_candidate_ids }) if param(:candidate_keyword)
      relation = relation.joins(:exam_application).where(exam_applications: { evaluation_target_id: matching_target_ids }) if param(:keyword)
      relation = relation.joins(:review_comments).where("review_comments.body_markdown LIKE ?", escaped_like(param(:comment_keyword))).distinct if param(:comment_keyword)
      relation
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
