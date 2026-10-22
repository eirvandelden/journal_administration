require "application_system_test_case"

class DashboardFiltersTest < ApplicationSystemTestCase
  setup do
    @user = users(:member)

    sign_in_as(@user)
  end

  test "quick filter this year selects January through the current month" do
    visit dashboard_index_url

    quick_filter.find("option", text: I18n.t("dashboard.filters.current_year", locale: locale)).select_option

    assert_select_value "from_month", Time.current.beginning_of_year.strftime("%Y-%m")
    assert_select_value "to_month", Time.current.strftime("%Y-%m")
  end

  private

  def quick_filter
    find("select[name='filter']")
  end

  def assert_select_value(name, value)
    assert_selector "select[name='#{name}'] option[selected][value='#{value}']", visible: :all
  end
end
