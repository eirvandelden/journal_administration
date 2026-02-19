require "test_helper"

class ResolvableTest < ActiveSupport::TestCase
  test "resolve_for_import finds by account number when present" do
    account = Account.resolve_for_import(
      account_number: accounts(:checking).account_number,
      description: "anything",
      name: "anything"
    )

    assert_equal accounts(:checking), account
  end

  test "resolve_for_import creates account when account number is unknown" do
    account = Account.resolve_for_import(
      account_number: "NL00NEW0000000001",
      description: "anything",
      name: "anything"
    )

    assert_equal "NL00NEW0000000001", account.account_number
  end

  test "resolve_for_import falls back to description matching when no account number" do
    account = Account.resolve_for_import(
      account_number: "",
      description: "Payment via #{accounts(:checking).account_number}",
      name: "Some Name"
    )

    assert_equal accounts(:checking), account
  end

  test "resolve_for_import falls back to normalized name when no account number or description match" do
    account = Account.resolve_for_import(
      account_number: "",
      description: "No match here",
      name: "AH Amsterdam"
    )

    assert_equal "Albert Heijn B.V.", account.name
  end
end
