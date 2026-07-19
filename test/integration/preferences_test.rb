require "test_helper"

class PreferencesTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
  end

  test "renders the preferences form for a signed-in user" do
    sign_in_as(@member)
    get edit_preferences_path

    assert_response :success
    assert_select "form"
    assert_select "select#user_color_scheme"
    assert_select "select#user_light_theme"
    assert_select "select#user_dark_theme"
    assert_select "select#user_locale"
  end

  test "unauthenticated request is redirected" do
    get edit_preferences_path

    assert_response :redirect
  end

  test "updates color_scheme, light_theme, and dark_theme" do
    sign_in_as(@member)

    patch preferences_path, params: { user: { color_scheme: "dark", light_theme: "solunized-white", dark_theme: "solunized-black" } }

    assert_redirected_to edit_preferences_path
    @member.reload
    assert @member.dark?
    assert @member.solunized_white?
    assert @member.solunized_black?
  end

  # JA's locale enum is integer-backed (`enum :locale, { nl: 0, en: 1, it: 2 }`),
  # but the engine's preferences form assigns the string locale code
  # (`I18n.available_locales`) straight to the enum attribute — verifying this
  # actually persists, not just assuming Rails enums accept it regardless of
  # underlying column type.
  test "persists a locale change through the integer-backed locale enum" do
    sign_in_as(@member)
    assert_equal "en", @member.locale

    patch preferences_path, params: { user: { locale: "nl" } }

    assert_redirected_to edit_preferences_path
    assert_equal "nl", @member.reload.locale
  end
end
