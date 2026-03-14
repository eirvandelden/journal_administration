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

  test "navigation does not show a separate filters menu" do
    visit root_url

    assert_no_selector "header nav summary", text: I18n.t("main_nav.dashboard_filters", locale: @locale)
  end

  private
    def assert_todo_link(label, path)
      visit root_url
      open_nav_section(I18n.t("main_nav.todo", model: Todo.model_name.human, locale: @locale))

      click_link label

      assert_current_path path, ignore_query: false
    end

    def open_nav_section(label)
      find("header nav summary", text: label).click
    end
end
