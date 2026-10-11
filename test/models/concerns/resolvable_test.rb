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

  test "resolves a migrated household account from an import description" do
    account = Account.resolve_for_import(
      account_number: "",
      description: "Payment to #{accounts(:checking).name}",
      name: "Household account"
    )

    assert_equal accounts(:checking), account
    assert_predicate account, :household_owned?
  end

  test "resolve_for_import falls back to normalized name when no account number or description match" do
    account = Account.resolve_for_import(
      account_number: "",
      description: "No match here",
      name: "AH Amsterdam"
    )

    assert_equal accounts(:albert_heijn), account
  end

  test "resolve_for_import books a provider payment on its merchant" do
    accounts(:adyen).update!(payment_provider: true)

    account = Account.resolve_for_import(
      account_number: accounts(:adyen).account_number,
      description: "Naam: Kruidvat Omschrijving: Payment IBAN: #{accounts(:adyen).account_number}",
      name: "Kruidvat"
    )

    assert_equal accounts(:kruidvat), account
  end
end
