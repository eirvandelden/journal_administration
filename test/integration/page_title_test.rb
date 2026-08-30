require "test_helper"

class PageTitleTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "title reflects the page's own heading" do
    account = accounts(:checking)
    get account_path(account)

    assert_select "title", text: account.name
  end

  test "title falls back to the app name when the page sets none" do
    get dashboard_index_url

    assert_select "title", text: Appkit.config.app_name.call
  end
end
