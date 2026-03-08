require "test_helper"

class Users::ProfilesTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @other = users(:admin)
  end

  test "user can view their own profile edit form" do
    sign_in_as(@member)
    get edit_user_profile_path(@member)

    assert_response :success
    assert_select "form"
  end

  test "user can see their session transfer link on the edit form" do
    sign_in_as(@member)
    get edit_user_profile_path(@member)

    assert_response :success
    assert_select "#session_transfer_url"
  end

  test "user can update their locale" do
    sign_in_as(@member)
    assert_equal "en", @member.locale

    patch user_profile_path(@member), params: { user: { locale: "nl" } }

    assert_redirected_to user_profile_path(@member)
    assert_equal "nl", @member.reload.locale
  end

  test "update with blank password keeps existing password digest" do
    sign_in_as(@member)
    original_digest = @member.password_digest

    patch user_profile_path(@member), params: { user: { name: "Updated Name", password: "" } }

    assert_redirected_to user_profile_path(@member)
    assert_equal original_digest, @member.reload.password_digest
  end

  test "update with invalid locale keeps existing locale" do
    sign_in_as(@member)
    original_locale = @member.locale

    patch user_profile_path(@member), params: { user: { locale: "unknown" } }

    assert_redirected_to user_profile_path(@member)
    assert_equal original_locale, @member.reload.locale
  end

  test "another user cannot access the edit form" do
    sign_in_as(@other)
    get edit_user_profile_path(@member)

    assert_response :forbidden
  end

  test "unauthenticated request is redirected" do
    get edit_user_profile_path(@member)

    assert_response :redirect
  end
end
