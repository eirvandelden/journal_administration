require "test_helper"

class MonthRangeTest < ActiveSupport::TestCase
  TODAY = Date.new(2026, 10, 22)

  test "from_selection prefers a known quick filter over months" do
    range = select(filter: "last_month", from_month: "2026-01", to_month: "2026-03")

    assert_period range, "2026-09-01", "2026-09-30"
  end

  test "from_selection ignores an unknown filter such as year_to_date" do
    range = select(filter: "year_to_date", from_month: "2026-01", to_month: "2026-03")

    assert_period range, "2026-01-01", "2026-03-31"
  end

  test "from_selection builds whole months from from_month and to_month" do
    range = select(from_month: "2026-02", to_month: "2026-02")

    assert_period range, "2026-02-01", "2026-02-28"
  end

  test "from_selection with February 2026 runs from 1 to 28 February" do
    range = select(from_month: "2026-02", to_month: "2026-02")

    assert_equal Time.zone.local(2026, 2, 1).beginning_of_day, range.start_date
    assert_equal Time.zone.local(2026, 2, 28).end_of_day, range.end_date
  end

  test "from_selection falls back to the current month" do
    [
      [ nil, nil ], [ "October", "2026-10" ], [ "2026-13", "2026-13" ],
      [ "2026-10-15", "2026-10-20" ], [ "2026-10", "2026-09" ], [ "2026-10", nil ]
    ].each do |from_month, to_month|
      range = select(from_month:, to_month:)

      assert_period range, "2026-10-01", "2026-10-31"
    end
  end

  test "current_year runs January through the end of this month" do
    assert_period select(filter: "current_year"), "2026-01-01", "2026-10-31"
  end

  test "current_month runs over this month" do
    assert_period select(filter: "current_month"), "2026-10-01", "2026-10-31"
  end

  test "three_months runs three months ago through last month" do
    assert_period select(filter: "three_months"), "2026-07-01", "2026-09-30"
  end

  test "last_year runs January through December of last year" do
    assert_period select(filter: "last_year"), "2025-01-01", "2025-12-31"
  end

  test "month_count counts one for October, one for February, three for January to March, twelve for a year" do
    assert_equal 1, select(from_month: "2026-10", to_month: "2026-10").month_count
    assert_equal 1, select(from_month: "2026-02", to_month: "2026-02").month_count
    assert_equal 3, select(from_month: "2026-01", to_month: "2026-03").month_count
    assert_equal 12, select(filter: "last_year").month_count
    assert_equal 14, select(from_month: "2025-01", to_month: "2026-02").month_count
  end

  test "refuses to be built from exact days" do
    assert_raises(NoMethodError) { MonthRange.new(Time.current, Time.current) }
    assert_raises(NoMethodError) { MonthRange.from_dates("2026-10-01", "2026-10-31") }
    assert_raises(NoMethodError) { MonthRange.from_filter("last_month") }
  end

  private

  def select(filter: nil, from_month: nil, to_month: nil)
    MonthRange.from_selection(filter:, from_month:, to_month:, today: TODAY)
  end

  def assert_period(range, first_day, last_day)
    assert_equal Date.parse(first_day), range.start_date.to_date
    assert_equal Date.parse(last_day), range.end_date.to_date
    assert_equal Date.parse(first_day).beginning_of_day, range.start_date
    assert_equal Date.parse(last_day).end_of_day, range.end_date
  end
end
