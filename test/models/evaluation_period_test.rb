require "test_helper"

class EvaluationPeriodTest < ActiveSupport::TestCase
  test "current scope returns active period containing date" do
    current = EvaluationPeriod.create!(
      name: "Current #{SecureRandom.hex(4)}",
      starts_on: Date.current - 1.day,
      ends_on: Date.current + 1.day
    )
    EvaluationPeriod.create!(
      name: "Past #{SecureRandom.hex(4)}",
      starts_on: Date.current - 10.days,
      ends_on: Date.current - 5.days
    )

    assert_includes EvaluationPeriod.current, current
  end

  test "requires valid date range" do
    period = EvaluationPeriod.new(
      name: "Invalid #{SecureRandom.hex(4)}",
      starts_on: Date.current,
      ends_on: Date.current - 1.day
    )

    assert_not period.valid?
    assert_includes period.errors[:ends_on], "must be on or after starts on"
  end

  test "name can be reused after soft delete but restore cannot create duplicate" do
    name = "Period #{SecureRandom.hex(4)}"
    deleted_period = EvaluationPeriod.create!(
      name: name,
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year
    )
    deleted_period.destroy
    EvaluationPeriod.create!(
      name: name,
      starts_on: Date.current.beginning_of_year,
      ends_on: Date.current.end_of_year
    )

    assert_no_difference -> { EvaluationPeriod.where(name: name).count } do
      deleted_period.restore(recursive: false)
    end
    assert deleted_period.reload.deleted?
  end
end
