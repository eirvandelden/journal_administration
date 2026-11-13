require "test_helper"

class MainNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @admin = users(:admin)
  end

  test "search button is the first rail item" do
    sign_in_as(@member)

    get dashboard_index_url

    assert_response :success
    assert_select "nav.rail > search:first-child > button[data-action='click->search-dialog#open']",
                  text: I18n.t("search.open")
  end

  test "new transaction page renders a visible back link to journal index" do
    sign_in_as(@member)

    get new_transaction_url

    assert_response :success
    assert_select "main > header nav a[href='#{transactions_path}']", text: I18n.t("common.back")
  end

  test "member reaches the profile and beheer through profiel but sees no admin link" do
    sign_in_as(@member)

    get hub_url(:profile)

    assert_response :success
    assert_select "nav.rail a[href='#{hub_path(:profile)}']", count: 1
    assert_select "nav.rail + nav a[href='#{edit_user_profile_path(@member)}']", count: 1
    assert_select "nav.rail + nav a[href='#{hub_path(:setup)}']", count: 1
    assert_select "a[href='#{admin_root_path}']", count: 0
  end

  test "administrator reaches the admin pages through Beheer" do
    sign_in_as(@admin)

    get hub_url(:setup)

    assert_response :success
    assert_select "nav.rail + nav a[href='#{admin_root_path}']", count: 1
    assert_select "nav.rail + nav a[href='#{admin_users_path}']", count: 1
  end

  test "the profiel hub column ends with the sign out link" do
    sign_in_as(@member)

    get hub_url(:profile)

    assert_select "nav.rail + nav > ul > li:last-child > a[href='#{session_path}'][data-turbo-method='delete']",
      text: I18n.t("menu.pages.sign_out.label")
    assert_select "nav.rail details", 0
  end
end
