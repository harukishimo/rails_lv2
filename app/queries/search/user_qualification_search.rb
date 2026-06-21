module Search
  class UserQualificationSearch < BaseSearch
    def relation
      paginate(filtered_scope.recent)
    end

    private

    def filtered_scope
      relation = scope.active.includes(
        :user,
        :granted_by,
        :exam_application,
        evaluation_target: %i[skill_area programming_language framework skill_level]
      )
      relation = relation.where(user_id: matching_user_ids) if param(:user_keyword)
      relation = relation.where(evaluation_target_id: param(:evaluation_target_id)) if param(:evaluation_target_id)
      relation = relation.where("acquired_on >= ?", param(:acquired_on_from)) if param(:acquired_on_from)
      relation = relation.where("acquired_on <= ?", param(:acquired_on_to)) if param(:acquired_on_to)
      relation
    end

    def matching_user_ids
      User.where("name LIKE :q OR email LIKE :q", q: escaped_like(param(:user_keyword))).select(:id)
    end
  end
end
