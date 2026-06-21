module Integrations
  module Slack
    class FaradayClient < BaseClient
      def initialize(webhook_url:, timeout: DEFAULT_TIMEOUT_SECONDS)
        @webhook_url = webhook_url
        super(timeout: timeout)
      end

      def post(payload:)
        response = handle_response!(post_payload(payload))

        Response.new(status: response.status, body: response.body, external_id: nil)
      end

      private

      attr_reader :webhook_url

      def post_payload(payload)
        connection(url: webhook_url).post do |request|
          request.headers.update(json_headers)
          request.body = JSON.generate(payload)
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => error
        raise RetryableError, error.message
      end
    end
  end
end
