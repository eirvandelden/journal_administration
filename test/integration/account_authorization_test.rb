require "test_helper"

class AccountAuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    Current.reset
  end

  test "Current.account returns the samen (shared) account" do
    Current.user = users(:member)

    assert_equal "samen", Current.account.owner
    assert_equal accounts(:checking).id, Current.account.id
  ensure
    Current.reset
  end

  test "Current.account falls back to Account.first when samen account doesn't exist" do
    shared_account = accounts(:checking)
    original_owner = shared_account.owner

    shared_account.update!(owner: :etienne)
    Current.reset
    Current.user = users(:member)

    assert_equal Account.first.id, Current.account.id
  ensure
    shared_account.update!(owner: original_owner) if shared_account&.persisted?
    Current.reset
  end

  test "dashboard shows samen account for all authenticated users" do
    etienne = users(:admin)
    michelle = users(:member)

    Current.user = etienne
    assert_equal accounts(:checking).id, Current.account.id

    Current.reset
    Current.user = michelle
    assert_equal accounts(:checking).id, Current.account.id
  ensure
    Current.reset
  end
end
