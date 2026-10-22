require "application_system_test_case"

class AdminUsersTest < ApplicationSystemTestCase
  setup do
    @member = users(:member)
    sign_in_as(users(:admin))
  end

  test "an administrator deletes a user from the edit page after the confirm" do
    visit edit_admin_user_url(@member)

    accept_confirm { click_on I18n.t("common.delete_ellipsis", locale: locale) }

    assert_current_path admin_users_path
    assert_not User.exists?(@member.id)
  end
end
