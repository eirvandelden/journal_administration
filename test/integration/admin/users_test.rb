require "test_helper"

class Admin::UsersTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @member = users(:member)
  end

  test "admin can list users" do
    sign_in_as(@admin)
    get admin_users_path

    assert_response :success
    assert_select "td", text: @member.email_address
  end

  test "admin can view a user" do
    sign_in_as(@admin)
    get admin_user_path(@member)

    assert_response :success
    assert_select "dd", text: @member.email_address
  end

  test "admin can reach new user form" do
    sign_in_as(@admin)
    get new_admin_user_path

    assert_response :success
    assert_select "form"
  end

  test "admin can edit a user" do
    sign_in_as(@admin)
    get edit_admin_user_path(@member)

    assert_response :success
    assert_select "form"
  end

  test "admin can update a user role" do
    sign_in_as(@admin)
    patch admin_user_path(@member), params: { user: { role: "administrator" } }

    assert_redirected_to admin_user_path(@member)
    assert_equal "administrator", @member.reload.role
  end

  test "admin cannot delete themselves" do
    sign_in_as(@admin)

    assert_no_difference("User.count") do
      delete admin_user_path(@admin)
    end

    assert_redirected_to admin_users_path
  end

  test "non-admin user is redirected for all actions" do
    sign_in_as(@member)

    get admin_users_path
    assert_redirected_to root_path
  end
end
