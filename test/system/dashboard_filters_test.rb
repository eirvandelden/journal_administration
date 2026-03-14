require "application_system_test_case"

class DashboardFiltersTest < ApplicationSystemTestCase
  setup do
    @user = users(:member)
    @locale = @user.locale.to_sym

    sign_in_as(@user)
  end

  test "quick filter uses local month boundaries" do
    set_browser_timezone("Europe/Amsterdam")
    visit dashboard_index_url

    quick_filter.find("option", text: I18n.t("dashboard.filters.current_month", locale: @locale)).select_option

    assert_selector "input[name='start_date'][value='#{Time.current.beginning_of_month.to_date.iso8601}']"
    assert_selector "input[name='end_date'][value='#{Time.current.end_of_month.to_date.iso8601}']"
  end

  private

  def quick_filter
    find("select[data-date-filter-target='quickFilter']")
  end

  def set_browser_timezone(timezone)
    page.driver.browser.execute_cdp("Emulation.setTimezoneOverride", timezoneId: timezone)
  end
end
