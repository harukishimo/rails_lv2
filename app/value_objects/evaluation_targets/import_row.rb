module EvaluationTargets
  class ImportRow < Struct.new(:number, :attributes, keyword_init: true)
    PERMITTED_ATTRIBUTES = %i[
      active
      description
      display_order
      external_knowledge_key
      external_knowledge_url
      framework_name
      programming_language_name
      skill_area_name
      skill_level_code
      skill_level_numeric_level
      version
    ].freeze

    def initialize(number:, attributes:)
      super(
        number: number,
        attributes: attributes.to_h.symbolize_keys.slice(*PERMITTED_ATTRIBUTES).freeze
      )
      freeze
    end

    def [](key)
      attributes[key.to_sym]
    end

    def key?(key)
      attributes.key?(key.to_sym)
    end

    def to_h
      attributes.dup
    end
  end
end
