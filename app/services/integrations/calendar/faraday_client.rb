module Integrations
  module Calendar
    class FaradayClient < BaseClient
      def initialize(api_url:, access_token:, timeout: DEFAULT_TIMEOUT_SECONDS)
        @api_url = api_url
        @access_token = access_token
        super(timeout: timeout)
      end

      def create_event(payload:)
        raw_response = post_payload(payload)
        return conflict_response(payload, raw_response) if raw_response.status == 409 && payload[:event_id].present?

        response = handle_response!(raw_response)
        body = JSON.parse(response.body.presence || "{}")

        Response.new(status: response.status, body: response.body, external_id: body["id"] || body["event_id"])
      end

      private

      attr_reader :api_url, :access_token

      def post_payload(payload)
        connection(url: api_url).post do |request|
          request.headers.update(json_headers.merge("Authorization" => "Bearer #{access_token}"))
          request.body = JSON.generate(google_payload(payload))
        end
      rescue Faraday::ConnectionFailed, Faraday::TimeoutError => error
        raise RetryableError, error.message
      end

      def google_payload(payload)
        {
          id: payload.fetch(:event_id),
          summary: payload.fetch(:summary),
          description: payload[:description],
          start: {
            dateTime: payload.dig(:start, :date_time),
            timeZone: payload.dig(:start, :time_zone)
          },
          end: {
            dateTime: payload.dig(:end, :date_time),
            timeZone: payload.dig(:end, :time_zone)
          },
          attendees: payload.fetch(:attendees),
          extendedProperties: {
            private: {
              skillEvidenceHubIdempotencyKey: payload.fetch(:idempotency_key)
            }
          }
        }
      end

      def conflict_response(payload, response)
        Response.new(status: response.status, body: response.body, external_id: payload.fetch(:event_id))
      end
    end
  end
end
