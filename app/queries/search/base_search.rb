module Search
  class BaseSearch
    DEFAULT_PER_PAGE = 50
    MAX_PER_PAGE = 100

    def initialize(scope, params = {})
      @scope = scope
      @params = params.to_h.symbolize_keys
    end

    private

    attr_reader :scope, :params

    def paginate(relation)
      relation.limit(per_page).offset((page - 1) * per_page)
    end

    def page
      [ params.fetch(:page, 1).to_i, 1 ].max
    end

    def per_page
      requested = params.fetch(:per_page, DEFAULT_PER_PAGE).to_i
      requested = DEFAULT_PER_PAGE if requested <= 0
      [ requested, MAX_PER_PAGE ].min
    end

    def param(key)
      params[key].presence
    end

    def enum_value(model, key, value)
      return if value.blank?

      value if model.public_send(key.to_s.pluralize).key?(value)
    end

    def escaped_like(value)
      "%#{ActiveRecord::Base.sanitize_sql_like(value.to_s)}%"
    end
  end
end
