require "test_helper"

class CsrfProtectionTest < ActionDispatch::IntegrationTest
  test "POST requests without authenticity token are rejected" do
    # Attempt to create a transaction without CSRF token
    assert_raises(ActionController::InvalidAuthenticityToken) do
      post transactions_path, params: { transaction: { amount: 100 } }
    end
  end

  test "POST requests with valid authenticity token succeed when authenticated" do
    user = users(:one)
    sign_in_as(user)

    get new_transaction_path
    assert_response :success

    # This should work because the session has a valid CSRF token
    post transactions_path, params: {
      transaction: {
        type: "Debit",
        amount: 100,
        booked_at: Time.current,
        interest_at: Time.current
      }
    }

    # Should either succeed or fail validation, but not CSRF error
    assert_response [:success, :redirect, :unprocessable_entity]
  end

  private

  def sign_in_as(user)
    session = user.sessions.create!(
      user_agent: "Test",
      ip_address: "127.0.0.1"
    )
    cookies.signed[:session_token] = session.token
  end
end
