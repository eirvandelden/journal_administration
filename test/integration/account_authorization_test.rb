require "test_helper"

class AccountAuthorizationTest < ActionDispatch::IntegrationTest
  test "Current.account maps user email to account owner" do
    # Create a user with email matching an account owner enum
    user = User.create!(
      name: "Etienne Test",
      email_address: "etienne@test.com",
      password: "password123",
      role: :member
    )

    # Create an account with matching owner
    account = Account.create!(
      name: "Etienne's Account",
      owner: :etienne
    )

    # Set current user
    Current.user = user

    # Verify Current.account returns the matching account
    assert_equal account.id, Current.account.id
    assert_equal "etienne", Current.account.owner
  end

  test "Current.account falls back to Account.first for unknown users" do
    # Create a user with email that doesn't match any owner enum
    user = User.create!(
      name: "Unknown User",
      email_address: "unknown@test.com",
      password: "password123",
      role: :member
    )

    # Ensure at least one account exists
    Account.create!(name: "Default Account", owner: :samen)

    Current.user = user

    # Should fall back to Account.first
    assert_equal Account.first.id, Current.account.id
  end

  test "Current.account returns Account.first when no user" do
    Current.user = nil

    # Should return Account.first
    assert_equal Account.first.id, Current.account.id
  end

  test "dashboard shows correct account data for authenticated user" do
    # This integration test would verify end-to-end that the dashboard
    # only shows data for the current user's account
    skip "Requires full authentication setup with fixtures"
  end
end
