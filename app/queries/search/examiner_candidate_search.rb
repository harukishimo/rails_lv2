module Search
  class ExaminerCandidateSearch < BaseSearch
    def initialize(scope, params = {}, visible_evaluation_target_ids: nil)
      super(scope, params)
      @visible_evaluation_target_ids = visible_evaluation_target_ids
    end

    def relation
      paginate(filtered_scope.order(:id))
    end

    private

    attr_reader :visible_evaluation_target_ids

    def filtered_scope
      relation = scope.includes(
        :roles,
        exam_applications: [
          :evaluation_period,
          { evaluation_target: %i[skill_area programming_language framework skill_level] }
        ],
        user_qualifications: [
          :granted_by,
          { evaluation_target: %i[skill_area programming_language framework skill_level] }
        ]
      )
      relation = relation.where("users.name LIKE :q OR users.email LIKE :q", q: escaped_like(param(:keyword))) if param(:keyword)
      relation = apply_exam_application_filters(relation)
      relation
    end

    def apply_exam_application_filters(relation)
      return relation unless param(:status) || param(:evaluation_target_id)

      conditions = exam_application_filter_conditions
      return relation.none if conditions[:evaluation_target_id] == []

      relation.joins(:exam_applications).where(exam_applications: conditions).distinct
    end

    def exam_application_filter_conditions
      conditions = {}
      conditions[:status] = enum_value(ExamApplication, :status, param(:status)) if param(:status)
      conditions[:evaluation_target_id] = constrained_evaluation_target_ids if constrained_evaluation_target_ids
      conditions
    end

    def constrained_evaluation_target_ids
      return requested_evaluation_target_id if visible_evaluation_target_ids.nil? && requested_evaluation_target_id
      return visible_evaluation_target_ids if requested_evaluation_target_id.blank? && param(:status)
      return unless requested_evaluation_target_id

      visible_evaluation_target_ids.include?(requested_evaluation_target_id.to_i) ? requested_evaluation_target_id : []
    end

    def requested_evaluation_target_id
      param(:evaluation_target_id)
    end
  end
end
