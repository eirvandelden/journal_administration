require "test_helper"

class AccountAuthorizationTest < ActionDispatch::IntegrationTest
  test "Current.account returns the samen (shared) account" do
    # Create the shared family account
    samen_account = Account.create!(
      name: "Shared Family Account",
      owner: :samen
    )

    # Create a user
    user = User.create!(
      name: "Etienne Test",
      email_address: "etienne@test.com",
      password: "password123",
      role: :member
    )

    # Set current user
    Current.user = user

    # Verify Current.account returns the samen account
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
    # This verifies that all family members see the same shared account
    samen_account = Account.create!(name: "Family Account", owner: :samen)

    etienne = User.create!(name: "Etienne", email_address: "etienne@test.com", password: "password123", role: :member)
    michelle = User.create!(name: "Michelle", email_address: "michelle@test.com", password: "password123", role: :member)

    # Both users should see the samen account
    Current.user = etienne
    assert_equal samen_account.id, Current.account.id

    Current.user = michelle
    assert_equal samen_account.id, Current.account.id
  end
end
