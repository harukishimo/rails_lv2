module Integrations
  module Slack
    class MockClient
      def post(payload:)
        Response.new(status: 200, body: JSON.generate(ok: true, mock: true, payload: payload), external_id: nil)
      end
    end
  end
end
