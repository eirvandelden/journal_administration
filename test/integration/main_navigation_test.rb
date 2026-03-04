require "test_helper"

class MainNavigationTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
  end

  test "primary nav keeps home and journal as direct links" do
    sign_in_as(@member)

    get dashboard_index_url

    assert_response :success
    assert_select "header nav > ul > li > a[href='#{dashboard_index_path}']", text: I18n.t("home")
    assert_select "header nav > ul > li > a[href='#{transactions_path}']", text: I18n.t("journal")
    assert_select "header nav summary a", count: 0
  end

  test "new transaction page renders a visible back link to journal index" do
    sign_in_as(@member)

    get new_transaction_url

    assert_response :success
    assert_select "header nav a[href='#{transactions_path}']", text: I18n.t("common.back")
  end
end
