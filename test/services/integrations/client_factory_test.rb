require "test_helper"

module Integrations
  class ClientFactoryTest < ActiveSupport::TestCase
    test "slack factory fails closed in production without webhook url" do
      error = assert_raises(Integrations::NonRetryableError) do
        Integrations::Slack::ClientFactory.build(env: {}, rails_env: "production")
      end

      assert_match(/Slack webhook URL is not configured/, error.message)
    end

    test "slack factory does not allow mock flag in production" do
      error = assert_raises(Integrations::NonRetryableError) do
        Integrations::Slack::ClientFactory.build(env: { "ALLOW_MOCK_INTEGRATIONS" => "true" }, rails_env: "production")
      end

      assert_match(/Slack webhook URL is not configured/, error.message)
    end

    test "slack factory allows mock in test without webhook url" do
      client = Integrations::Slack::ClientFactory.build(env: {}, rails_env: "test")

      assert_instance_of Integrations::Slack::MockClient, client
    end

    test "calendar factory fails closed in production without calendar credentials" do
      error = assert_raises(Integrations::NonRetryableError) do
        Integrations::Calendar::ClientFactory.build(env: {}, rails_env: "production")
      end

      assert_match(/Google Calendar integration is not configured/, error.message)
    end

    test "calendar factory does not allow mock flag in production" do
      error = assert_raises(Integrations::NonRetryableError) do
        Integrations::Calendar::ClientFactory.build(
          env: { "ALLOW_MOCK_INTEGRATIONS" => "true" },
          rails_env: "production"
        )
      end

      assert_match(/Google Calendar integration is not configured/, error.message)
    end

    test "calendar factory allows mock in test without calendar credentials" do
      client = Integrations::Calendar::ClientFactory.build(env: {}, rails_env: "test")

      assert_instance_of Integrations::Calendar::MockClient, client
    end
  end
end
