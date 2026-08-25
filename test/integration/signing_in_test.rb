require "test_helper"

class SigningInTest < ActionDispatch::IntegrationTest
  test "signing in as someone else replaces the current sign-in" do
    sign_in_as users(:admin)

    sign_in_as users(:member)
    get root_url

    assert_select "a[href=?]", edit_user_profile_path(users(:member))
  end
end
