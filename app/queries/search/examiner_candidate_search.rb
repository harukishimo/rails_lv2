module Search
  class ExaminerCandidateSearch < BaseSearch
    DEFAULT_EXCLUDED_EXAM_STATUSES = %w[failed canceled closed].freeze

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
      filter = exam_application_filter
      return relation.none if filter == :none

      relation.joins(:exam_applications).merge(filter).distinct
    end

    def exam_application_filter
      target_ids = constrained_evaluation_target_ids
      return :none if target_ids == []

      relation = ExamApplication.all
      relation = apply_status_filter(relation)
      relation = relation.where(evaluation_target_id: target_ids) if target_ids
      relation
    end

    def apply_status_filter(relation)
      selected_statuses = selected_status_values
      return relation.where(status: selected_statuses) if selected_statuses.any?
      return relation if status_filter_requested?

      relation.where.not(status: ExamApplication.statuses.values_at(*DEFAULT_EXCLUDED_EXAM_STATUSES))
    end

    def selected_status_values
      values = enum_values(ExamApplication, :status, array_param(:statuses))
      values.presence || Array.wrap(enum_value(ExamApplication, :status, param(:status))).compact
    end

    def status_filter_requested?
      param(:status).present? || array_param(:statuses).any?
    end

    def constrained_evaluation_target_ids
      return requested_evaluation_target_id if visible_evaluation_target_ids.nil? && requested_evaluation_target_id
      return visible_evaluation_target_ids if requested_evaluation_target_id.blank? && visible_evaluation_target_ids
      return unless requested_evaluation_target_id

      visible_evaluation_target_ids.include?(requested_evaluation_target_id.to_i) ? requested_evaluation_target_id : []
    end

    def requested_evaluation_target_id
      param(:evaluation_target_id)
    end
  end
end
