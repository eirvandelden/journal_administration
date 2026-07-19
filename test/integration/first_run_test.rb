require "test_helper"

# Exercises Appkit.config.email_attribute (:email_address, JA's actual column)
# end-to-end through the FirstRun bootstrap flow, not just the login form.
class FirstRunTest < ActionDispatch::IntegrationTest
  setup do
    Session.delete_all
    User.delete_all
  end

  test "visiting session new redirects to first_run when no users exist" do
    get new_session_url

    assert_redirected_to first_run_url
  end

  test "first_run show redirects to root once a user exists" do
    User.create!(name: "Existing", email_address: "existing@example.com", password: "password", role: :member, locale: :en)

    get first_run_url

    assert_redirected_to root_url
  end

  test "first_run create makes the first user an administrator with a default locale, and starts a session" do
    assert_difference -> { User.count }, 1 do
      post first_run_url, params: { user: { name: "New Person", email_address: "new@example.com", password: "password" } }
    end

    assert_redirected_to root_url
    assert User.last.administrator?
    assert_equal "en", User.last.locale
    assert cookies[:session_token].present?
  end

  test "first_run create is not permitted once a user exists" do
    User.create!(name: "Existing", email_address: "existing@example.com", password: "password", role: :member, locale: :en)

    assert_no_difference -> { User.count } do
      post first_run_url, params: { user: { name: "New Person", email_address: "new@example.com", password: "password" } }
    end

    assert_redirected_to root_url
  end
end
