require "test_helper"

class MainNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @admin = users(:admin)
  end

  test "primary nav keeps home and journal as direct links" do
    sign_in_as(@member)

    get dashboard_index_url

    assert_response :success
    assert_select "header nav > ul > li > a[href='#{dashboard_index_path}']", text: I18n.t("home")
    assert_select "header nav > ul > li > a[href='#{transactions_path}']", text: I18n.t("journal")
    assert_select "header nav summary", text: I18n.t("main_nav.dashboard_filters"), count: 0
    assert_select "header nav summary", text: I18n.t("main_nav.todo", model: Todo.model_name.human), count: 1
    assert_select "header nav summary a", count: 0
  end

  test "new transaction page renders a visible back link to journal index" do
    sign_in_as(@member)

    get new_transaction_url

    assert_response :success
    assert_select "header nav a[href='#{transactions_path}']", text: I18n.t("common.back")
  end

  test "member sees profile link but not admin link" do
    sign_in_as(@member)

    get dashboard_index_url

    assert_response :success
    assert_select "header nav a[href='#{edit_user_profile_path(@member)}']", count: 1
    assert_select "header nav a[href='#{admin_root_path}']", count: 0
  end

  test "administrator sees profile and admin links" do
    sign_in_as(@admin)

    get dashboard_index_url

    assert_response :success
    assert_select "header nav a[href='#{edit_user_profile_path(@admin)}']", count: 1
    assert_select "header nav a[href='#{admin_root_path}']", count: 1
  end
end
