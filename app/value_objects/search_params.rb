class SearchParams < Struct.new(:context, :values, :unknown_keys, :allowed_keys, keyword_init: true)
  class UnknownKeyError < ArgumentError; end

  CONTEXTS = {
    evaluation_target: %i[
      active
      framework_id
      keyword
      page
      per_page
      programming_language_id
      skill_area_id
      skill_level_id
    ],
    exam_application: %i[
      candidate_id
      evaluation_target_id
      keyword
      page
      per_page
      result
      status
      statuses
    ],
    interview_queue: %i[
      candidate_keyword
      evaluation_target_id
      keyword
      page
      per_page
      status
      statuses
    ],
    review_queue: %i[
      candidate_keyword
      comment_keyword
      evaluation_target_id
      keyword
      page
      per_page
      status
      statuses
    ],
    examiner_candidate: %i[
      evaluation_target_id
      keyword
      page
      per_page
      status
      statuses
    ],
    user_qualification: %i[
      acquired_on_from
      acquired_on_to
      evaluation_target_id
      page
      per_page
      user_keyword
    ]
  }.transform_values(&:freeze).freeze

  METHOD_NAMES = CONTEXTS.values.flatten.uniq.freeze

  METHOD_NAMES.each do |method_name|
    define_method(method_name) do
      self[method_name]
    end
  end

  def self.for(context, params)
    normalized_context = context.to_sym
    allowed_keys = CONTEXTS.fetch(normalized_context)
    normalized_values = params.to_h.symbolize_keys
    values = normalized_values.slice(*allowed_keys).freeze
    unknown_keys = (normalized_values.keys - allowed_keys).freeze

    new(
      context: normalized_context,
      values: values,
      unknown_keys: unknown_keys,
      allowed_keys: allowed_keys
    ).freeze
  end

  def self.context_for(search_class_name)
    search_class_name.demodulize.delete_suffix("Search").underscore.to_sym
  end

  def [](key)
    values[key.to_sym]
  end

  def key?(key)
    values.key?(key.to_sym)
  end

  def to_h
    values.dup
  end

  def assert_known!
    return self if unknown_keys.empty?

    raise UnknownKeyError, "Unknown search parameters for #{context}: #{unknown_keys.join(', ')}"
  end
end
