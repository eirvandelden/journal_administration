require "test_helper"

class AccountAuthorizationTest < ActionDispatch::IntegrationTest
  test "Current.account returns the samen (shared) account" do
    samen_account = accounts(:checking)

    user = users(:member)
    Current.user = user

    assert_equal samen_account.id, Current.account.id
    assert_equal "samen", Current.account.owner
  end

  test "Current.account falls back to Account.first when samen account doesn't exist" do
    # Ensure at least one account exists (but not samen)
    fallback_account = Account.create!(name: "Fallback Account", owner: :etienne)

    user = User.create!(
      name: "Test User",
      email_address: "test@test.com",
      password: "password123",
      role: :member
    )

    Current.user = user

    # Should fall back to Account.first since samen doesn't exist
    assert_equal Account.first.id, Current.account.id
  end

  test "dashboard shows samen account for all authenticated users" do
    samen_account = accounts(:checking)

    etienne = users(:admin)
    michelle = users(:member)

    # Both users should see the samen account
    Current.user = etienne
    assert_equal samen_account.id, Current.account.id

    Current.user = michelle
    assert_equal samen_account.id, Current.account.id
  end
end
