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

  test "from_filter with year_to_date returns current year range" do
    range = DateRange.from_filter("year_to_date")

    assert_equal Time.current.beginning_of_year.to_date, range.start_date.to_date
    assert_equal Time.current.end_of_year.to_date, range.end_date.to_date
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
end
