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

  test "admin update with blank passwords keeps existing password" do
    sign_in_as(@admin)
    original_digest = @member.password_digest

    patch admin_user_path(@member), params: { user: { name: "Updated Member", password: "", password_confirmation: "" } }

    assert_redirected_to admin_user_path(@member)
    assert_equal original_digest, @member.reload.password_digest
    assert @member.authenticate("password123")
  end

  test "admin update with invalid role does not raise and keeps existing role" do
    sign_in_as(@admin)

    patch admin_user_path(@member), params: { user: { role: "not-a-role" } }

    assert_redirected_to admin_user_path(@member)
    assert_equal "member", @member.reload.role
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

    get admin_user_path(@admin)
    assert_redirected_to root_path

    get new_admin_user_path
    assert_redirected_to root_path

    post admin_users_path,
         params: { user: {
           name: "No Admin",
           email_address: "no-admin@example.com",
           role: "member",
           password: "password123",
           password_confirmation: "password123"
         } }
    assert_redirected_to root_path

    get edit_admin_user_path(@admin)
    assert_redirected_to root_path

    patch admin_user_path(@admin), params: { user: { role: "member" } }
    assert_redirected_to root_path

    delete admin_user_path(@admin)
    assert_redirected_to root_path
  end
end
