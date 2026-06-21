require "cgi"

module Integrations
  module Calendar
    class ClientFactory
      def self.build(env: ENV, rails_env: Rails.env)
        new(env: env, rails_env: rails_env).build
      end

      def initialize(env:, rails_env:)
        @env = env
        @rails_env = ActiveSupport::StringInquirer.new(rails_env.to_s)
      end

      def build
        return FaradayClient.new(api_url: api_url, access_token: access_token) if real_client_configured?
        return MockClient.new if mock_allowed?

        raise NonRetryableError, "Google Calendar integration is not configured"
      end

      private

      attr_reader :env, :rails_env

      def mock_allowed?
        return false if rails_env.production?

        rails_env.development? || rails_env.test? || env["ALLOW_MOCK_INTEGRATIONS"] == "true"
      end

      def real_client_configured?
        api_url.present? && access_token.present?
      end

      def api_url
        env["GOOGLE_CALENDAR_API_URL"].presence || calendar_api_url_from_id
      end

      def calendar_api_url_from_id
        calendar_id = env["GOOGLE_CALENDAR_ID"]
        return if calendar_id.blank?

        "https://www.googleapis.com/calendar/v3/calendars/#{CGI.escape(calendar_id)}/events"
      end

      def access_token
        env["GOOGLE_CALENDAR_ACCESS_TOKEN"]
      end
    end
  end
end
