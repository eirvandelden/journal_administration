require "application_system_test_case"

class MainNavigationMenusTest < ApplicationSystemTestCase
  setup do
    @user = users(:member)

    sign_in_as(@user)
  end

  test "the rail links reach each hub landing page" do
    visit root_url

    click_link I18n.t("menu.hubs.processing.label", locale: locale)

    assert_current_path hub_path(:processing)
  end

  test "the verwerken import action reaches the import page" do
    visit hub_url(:processing)

    click_link I18n.t("menu.hubs.processing.import", locale: locale)

    assert_current_path new_transactions_import_path
  end

  test "a hub column link reaches budgets" do
    visit hub_url(:planning)

    click_link I18n.t("menu.pages.budgets.label", locale: locale), match: :first

    assert_current_path budgets_path, ignore_query: true
  end
end
