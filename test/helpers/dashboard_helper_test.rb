require "test_helper"

class DashboardHelperTest < ActionView::TestCase
  MONTHS = [ Date.new(2027, 1, 1), Date.new(2026, 12, 1), Date.new(2026, 11, 1) ].freeze

  test "month_options labels each month in the current locale" do
    html = I18n.with_locale(:nl) { month_options(MONTHS, selected: Date.new(2026, 12, 1)) }

    assert_dom_equal_option html, "2026-12", "december 2026"
  end

  test "month_options values each month as YYYY-MM" do
    html = month_options(MONTHS, selected: Date.new(2026, 12, 1))

    assert_select_in html, "option", count: 3
    assert_select_in html, "option[value='2027-01']"
    assert_select_in html, "option[value='2026-11']"
  end

  test "month_options groups months per year" do
    html = month_options(MONTHS, selected: Date.new(2026, 12, 1))

    assert_select_in html, "optgroup[label='2027'] option", count: 1
    assert_select_in html, "optgroup[label='2026'] option", count: 2
  end

  test "month_options marks the selected month" do
    html = month_options(MONTHS, selected: Date.new(2026, 12, 15))

    assert_select_in html, "option[selected][value='2026-12']", count: 1
    assert_select_in html, "option[selected]", count: 1
  end

  private

  def assert_select_in(html, selector, **options)
    assert_select Nokogiri::HTML.fragment(html), selector, **options
  end

  def assert_dom_equal_option(html, value, label)
    assert_select_in html, "option[value='#{value}']", text: label
  end
end
