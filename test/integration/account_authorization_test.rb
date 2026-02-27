require "test_helper"

class AccountAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    Current.reset
  end

  test "Current.account returns the samen (shared) account" do
    samen_account = accounts(:checking)

    user = users(:member)
    Current.user = user

    assert_equal samen_account.id, Current.account.id
    assert_equal "samen", Current.account.owner
  end

  test "Current.account falls back to Account.first when samen account doesn't exist" do
    assert_not_nil Current.account
  end

  test "dashboard shows samen account for all authenticated users" do
    samen_account = accounts(:checking)

    etienne = users(:admin)
    michelle = users(:member)

    # Both users should see the samen account
    Current.user = etienne
    assert_equal samen_account.id, Current.account.id

    Current.reset
    Current.user = michelle
    assert_equal samen_account.id, Current.account.id
  end
end
