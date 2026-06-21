module Integrations
  class SecretRedactor
    SECRET_ENV_PATTERN = /(SECRET|TOKEN|KEY|WEBHOOK|PASSWORD|CREDENTIAL)/i

    def self.call(value, env: ENV)
      new(env: env).call(value)
    end

    def initialize(env: ENV)
      @env = env
    end

    def call(value)
      case value
      when Hash
        value.transform_values { |child| call(child) }
      when Array
        value.map { |child| call(child) }
      when NilClass, Numeric, TrueClass, FalseClass
        value
      else
        redact_text(value.to_s)
      end
    end

    private

    attr_reader :env

    def redact_text(text)
      text = text.dup
      secret_values.each do |secret|
        text.gsub!(secret, "[FILTERED]")
      end
      text
    end

    def secret_values
      env.each_with_object([]) do |(key, value), values|
        next unless key.match?(SECRET_ENV_PATTERN)
        next if value.blank? || value.length < 8

        values << value
      end
    end
  end
end
