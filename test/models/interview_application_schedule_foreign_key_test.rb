require "test_helper"

class InterviewApplicationScheduleForeignKeyTest < ActiveSupport::TestCase
  test "database rejects interview application without existing exam application" do
    now = Time.current

    assert_raises(ActiveRecord::InvalidForeignKey) do
      InterviewApplication.insert_all!([
        {
          exam_application_id: -1,
          status: InterviewApplication.statuses.fetch("requested"),
          requested_at: now,
          lock_version: 0,
          created_at: now,
          updated_at: now
        }
      ])
    end
  end

  test "database rejects interview schedule without existing interview application" do
    now = Time.current

    assert_raises(ActiveRecord::InvalidForeignKey) do
      InterviewSchedule.insert_all!([
        {
          interview_application_id: -1,
          starts_at: 2.days.from_now,
          ends_at: 2.days.from_now + 30.minutes,
          timezone: "Asia/Tokyo",
          status: InterviewSchedule.statuses.fetch("requested"),
          created_at: now,
          updated_at: now
        }
      ])
    end
  end
end
