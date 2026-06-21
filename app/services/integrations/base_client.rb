module Integrations
  class BaseClient
    DEFAULT_TIMEOUT_SECONDS = 5

    def initialize(timeout: DEFAULT_TIMEOUT_SECONDS)
      @timeout = timeout
    end

    private

    attr_reader :timeout

    def connection(url:)
      Faraday.new(url: url) do |faraday|
        faraday.options.timeout = timeout
        faraday.options.open_timeout = timeout
        faraday.adapter Faraday.default_adapter
      end
    end

    def handle_response!(response)
      case response.status
      when 200..299
        response
      when 429, 500..599
        raise RetryableError.new(
          "external service returned #{response.status}",
          status: response.status,
          body: response.body
        )
      else
        raise NonRetryableError.new(
          "external service returned #{response.status}",
          status: response.status,
          body: response.body
        )
      end
    rescue Faraday::ConnectionFailed, Faraday::TimeoutError => error
      raise RetryableError, error.message
    end

    def json_headers
      { "Content-Type" => "application/json" }
    end
  end
end
