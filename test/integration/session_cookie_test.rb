require "test_helper"

class SessionCookieTest < ActionDispatch::IntegrationTest
  test "login sets a far-future session cookie expiry" do
    post session_url, params: { email_address: users(:admin).email_address, password: "password123" }

    assert_session_cookie_expires_far_in_future
  end

  test "resuming a session renews the cookie expiry" do
    sign_in_as users(:member)

    get root_url

    assert_session_cookie_expires_far_in_future
  end

  private

  def assert_session_cookie_expires_far_in_future
    set_cookie_headers = Array(response.headers["Set-Cookie"])
    set_cookie = set_cookie_headers.find { |c| c.include?("session_token") }
    assert set_cookie, "Expected a Set-Cookie header for session_token"

    expires_match = set_cookie.match(/expires=([^;]+)/i)
    assert expires_match, "Expected Set-Cookie to include expires="

    expires_at = Time.parse(expires_match[1])
    assert expires_at > 6.months.from_now,
      "Expected cookie to expire more than 6 months from now, got #{expires_at}"
  end
end
