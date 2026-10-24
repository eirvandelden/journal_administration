require "test_helper"

class LoginLayoutTest < ActionDispatch::IntegrationTest
  test "a signed-out visitor's page leaves the theme to the browser" do
    get new_session_path

    assert_select "html[data-controller=?]", "theme"
    assert_select "html[data-theme]", count: 0
    assert_select "html[data-color-scheme]", count: 0
  end
end
