require "test_helper"

class DateRangeTest < ActiveSupport::TestCase
  test "from_filter with last_month returns last month range" do
    range = DateRange.from_filter("last_month")

    assert_equal Time.current.last_month.beginning_of_month.to_date, range.start_date.to_date
    assert_equal Time.current.last_month.end_of_month.to_date, range.end_date.to_date
  end

  test "from_filter with three_months returns three month range" do
    range = DateRange.from_filter("three_months")

    assert_equal Time.current.months_ago(3).beginning_of_month.to_date, range.start_date.to_date
    assert_equal Time.current.last_month.end_of_month.to_date, range.end_date.to_date
  end

  test "from_filter with year_to_date returns the current year up to today" do
    range = DateRange.from_filter("year_to_date")

    assert_equal Time.current.beginning_of_year.to_date, range.start_date.to_date
    assert_equal Time.current.to_date, range.end_date.to_date
  end

  test "from_filter with last_year returns last year range" do
    range = DateRange.from_filter("last_year")

    assert_equal Time.current.last_year.beginning_of_year.to_date, range.start_date.to_date
    assert_equal Time.current.last_year.end_of_year.to_date, range.end_date.to_date
  end

  test "from_filter with nil defaults to current month" do
    range = DateRange.from_filter(nil)

    assert_equal Time.current.beginning_of_month.to_date, range.start_date.to_date
    assert_equal Time.current.end_of_month.to_date, range.end_date.to_date
  end

  test "to_range returns a Range" do
    range = DateRange.from_filter("last_month")

    assert_instance_of Range, range.to_range
    assert_equal range.start_date, range.to_range.begin
    assert_equal range.end_date, range.to_range.end
  end

  test "FILTERS contains all valid filter options" do
    assert_includes DateRange::FILTERS, "last_month"
    assert_includes DateRange::FILTERS, "three_months"
    assert_includes DateRange::FILTERS, "year_to_date"
    assert_includes DateRange::FILTERS, "last_year"
    assert_includes DateRange::FILTERS, "current_month"
  end

  test "from_dates creates a DateRange with specified start and end dates" do
    start_date = "2026-03-01"
    end_date = "2026-03-31"
    range = DateRange.from_dates(start_date, end_date)

    assert_equal Date.parse(start_date), range.start_date.to_date
    assert_equal Date.parse(end_date), range.end_date.to_date
  end

  test "from_dates handles Date objects" do
    start_date = Date.current.beginning_of_month
    end_date = Date.current.end_of_month
    range = DateRange.from_dates(start_date, end_date)

    assert_equal start_date, range.start_date.to_date
    assert_equal end_date, range.end_date.to_date
  end

  test "from_dates returns nil for invalid dates" do
    range = DateRange.from_dates("not-a-date", "2026-03-31")

    assert_nil range
  end

  test "days counts both ends" do
    range = DateRange.from_dates("2026-10-15", "2026-10-20")

    assert_equal 6, range.days
  end

  test "month_count is days over thirty" do
    range = DateRange.from_dates("2026-10-11", "2026-10-20")

    assert_in_delta 10 / 30.0, range.month_count
  end

  test "from_dates returns a MonthRange for 1 to 31 October" do
    range = DateRange.from_dates("2026-10-01", "2026-10-31")

    assert_instance_of MonthRange, range
    assert_equal 1, range.month_count
  end

  test "from_dates returns a plain DateRange for 15 to 20 October" do
    range = DateRange.from_dates("2026-10-15", "2026-10-20")

    assert_instance_of DateRange, range
  end
end
