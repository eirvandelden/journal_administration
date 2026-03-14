require "application_system_test_case"

class MainNavigationMenusTest < ApplicationSystemTestCase
  setup do
    @user = users(:member)
    @locale = @user.locale.to_sym

    sign_in_as(@user)
  end

  test "todo menu links reach the expected pages" do
    assert_todo_link(I18n.t("main_nav.todo_all", locale: @locale), todo_path)
    assert_todo_link(I18n.t("main_nav.todo_consolidatable_transactions", locale: @locale),
                     transactions_path(filter: :no_category))
    assert_todo_link(I18n.t("main_nav.todo_consolidatable_accounts", locale: @locale),
                     accounts_path(filter: :untouched))
    assert_todo_link(I18n.t("main_nav.todo_upload", locale: @locale), new_transactions_import_path)
  end

  test "dashboard filter menu links keep the selected filter in the URL" do
    assert_dashboard_filter_link(I18n.t("filters.month_to_date", locale: @locale), :month_to_date)
    assert_dashboard_filter_link(I18n.t("filters.last_month", locale: @locale), :last_month)
    assert_dashboard_filter_link(I18n.t("filters.three_months", locale: @locale), :three_months)
    assert_dashboard_filter_link(I18n.t("filters.year_to_date", locale: @locale), :year_to_date)
    assert_dashboard_filter_link(I18n.t("filters.last_year", locale: @locale), :last_year)
  end

  private
    def assert_todo_link(label, path)
      visit root_url
      open_nav_section(I18n.t("main_nav.todo_views", locale: @locale))

      click_link label

      assert_current_path path, ignore_query: false
    end

    def assert_dashboard_filter_link(label, filter)
      visit root_url
      open_nav_section(I18n.t("main_nav.dashboard_filters", locale: @locale))

      click_link label

      assert_current_path dashboard_index_path(filter: filter), ignore_query: false
    end

    def open_nav_section(label)
      find("header nav summary", text: label).click
    end
end
