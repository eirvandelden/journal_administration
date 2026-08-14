require "test_helper"

class LoginThemeTest < ActionDispatch::IntegrationTest
  test "login page declares colour-scheme support" do
    get new_session_path
    assert_select "meta[name='color-scheme']"
  end
end
