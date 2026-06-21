module Integrations
  module Slack
    class ClientFactory
      DEFAULT_WEBHOOK_NAME = "default".freeze

      def self.build(webhook_name: DEFAULT_WEBHOOK_NAME, env: ENV, rails_env: Rails.env)
        new(webhook_name: webhook_name, env: env, rails_env: rails_env).build
      end

      def initialize(webhook_name:, env:, rails_env:)
        @webhook_name = webhook_name
        @env = env
        @rails_env = ActiveSupport::StringInquirer.new(rails_env.to_s)
      end

      def build
        return FaradayClient.new(webhook_url: webhook_url) if webhook_url.present?
        return MockClient.new if mock_allowed?

        raise NonRetryableError, "Slack webhook URL is not configured"
      end

      private

      attr_reader :webhook_name, :env, :rails_env

      def mock_allowed?
        return false if rails_env.production?

        rails_env.development? || rails_env.test? || env["ALLOW_MOCK_INTEGRATIONS"] == "true"
      end

      def webhook_url
        env[webhook_env_key] || env["SLACK_WEBHOOK_URL"]
      end

      def webhook_env_key
        "SLACK_WEBHOOK_#{webhook_name.to_s.upcase.gsub(/[^A-Z0-9]+/, "_")}_URL"
      end
    end
  end
end
