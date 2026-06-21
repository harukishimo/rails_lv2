require "test_helper"

class Integrations::Calendar::EventPayloadTest < ActiveSupport::TestCase
  test "payload value object renders immutable calendar event hash" do
    start_time = Time.zone.parse("2026-06-21 10:00")
    end_time = Time.zone.parse("2026-06-21 10:30")
    payload = Integrations::Calendar::EventPayload::Payload.new(
      idempotency_key: "interview_schedule:1",
      event_id: "seh123",
      summary: "SkillEvidenceHub 評価面談",
      description: "Evaluation interview",
      start_time: start_time,
      end_time: end_time,
      time_zone: "Asia/Tokyo",
      attendee_emails: %w[candidate@example.com examiner@example.com]
    )

    rendered = payload.to_h

    assert payload.frozen?
    assert payload.attendee_emails.frozen?
    assert_equal "seh123", rendered.fetch(:event_id)
    assert_equal start_time.iso8601, rendered.dig(:start, :date_time)
    assert_equal end_time.iso8601, rendered.dig(:end, :date_time)
    assert_equal [ { email: "candidate@example.com" }, { email: "examiner@example.com" } ], rendered.fetch(:attendees)
  end

  test "payload key allowlist is immutable" do
    assert Integrations::Calendar::EventPayload::PAYLOAD_KEYS.frozen?
    assert_raises(FrozenError) do
      Integrations::Calendar::EventPayload::PAYLOAD_KEYS << :unsafe
    end
  end
end
