module Exporters
  module CellSanitizer
    DANGEROUS_FORMULA_PREFIX = /\A[[:space:][:cntrl:]]*[=+\-@]/.freeze

    module_function

    def call(value)
      return value unless value.is_a?(String)
      return "'#{value}" if value.match?(DANGEROUS_FORMULA_PREFIX)

      value
    end
  end
end
