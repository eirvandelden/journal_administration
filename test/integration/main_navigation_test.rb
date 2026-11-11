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

  test "member sees the profile link in the account menu but no admin link" do
    sign_in_as(@member)

    get dashboard_index_url

    assert_response :success
    assert_select "nav.rail details a[href='#{edit_user_profile_path(@member)}']", count: 1
    assert_select "nav.rail details a[href='#{hub_path(:setup)}']", count: 1
    assert_select "nav.rail a[href='#{admin_root_path}']", count: 0
  end

  test "administrator reaches the admin pages through Beheer" do
    sign_in_as(@admin)

    get hub_url(:setup)

    assert_response :success
    assert_select "nav.hub-column a[href='#{admin_root_path}']", count: 1
    assert_select "nav.hub-column a[href='#{admin_users_path}']", count: 1
  end

  test "the account menu ends with the sign out button" do
    sign_in_as(@member)

    get dashboard_index_url

    assert_select "nav.rail details form[action='#{session_path}'] button"
  end
end
