require "test_helper"

class CsrfProtectionTest < ActionDispatch::IntegrationTest
  setup { ApplicationController.allow_forgery_protection = true }
  teardown { ApplicationController.allow_forgery_protection = false }

  test "POST requests without authenticity token are rejected" do
    sign_in_as(users(:member))

    # Attempt to create a transaction without CSRF token
    # show_exceptions = :rescuable catches InvalidAuthenticityToken and renders 422
    post transactions_path, params: { transaction: { amount: 100 } }
    assert_response :unprocessable_entity
  end

  test "POST requests with valid authenticity token succeed when authenticated" do
    sign_in_as(users(:member))

    get root_path
    assert_response :success

    # Sign out using DELETE with valid CSRF token - verifies token is accepted
    delete session_path, headers: { "X-CSRF-Token" => session[:_csrf_token] }
    assert_response :redirect
  end

  private

  def sign_in_as(user)
    ApplicationController.allow_forgery_protection = false
    post session_path, params: { email_address: user.email_address, password: "password123" }
    ApplicationController.allow_forgery_protection = true
  end
end
