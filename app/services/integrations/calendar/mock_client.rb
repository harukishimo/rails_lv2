module Integrations
  module Calendar
    class MockClient
      def create_event(payload:)
        event_id = payload.fetch(:event_id)

        Response.new(status: 200, body: JSON.generate(id: event_id, mock: true), external_id: event_id)
      end
    end
  end
end
