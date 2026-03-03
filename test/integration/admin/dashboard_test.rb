require "test_helper"

class Admin::DashboardTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:member)
  end

  test "non-admin user is redirected away" do
    sign_in_as(@member)
    get admin_root_path

    assert_redirected_to root_path
  end

  test "admin can access dashboard and sees user table" do
    sign_in_as(@admin)
    get admin_root_path

    assert_response :success
    assert_select "table"
    assert_select "td", text: @admin.email_address
  end

  test "dashboard shows user counts" do
    sign_in_as(@admin)
    get admin_root_path

    assert_response :success
    assert_select "dd", text: User.count.to_s
    assert_select "dd", text: User.administrator.count.to_s
  end
end
