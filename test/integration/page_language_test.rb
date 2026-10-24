require "test_helper"

class PageLanguageTest < ActionDispatch::IntegrationTest
  test "a Dutch user gets lang nl" do
    sign_in_as(users(:admin))

    get dashboard_index_path

    assert_select "html[lang=?]", "nl"
  end

  test "an English user gets lang en" do
    sign_in_as(users(:member))

    get dashboard_index_path

    assert_select "html[lang=?]", "en"
  end

  test "the admin layout declares the user's language" do
    sign_in_as(users(:admin))

    get admin_root_path

    assert_select "html[lang=?]", "nl"
  end

  test "a signed-out visitor gets the default locale" do
    get new_session_path

    assert_select "html[lang=?]", I18n.default_locale.to_s
  end
end
