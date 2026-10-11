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

  test "resolve_from_description ignores a household account with a blank account number" do
    Account.create!(name: "Blank number household", person: people(:etienne), account_number: "")

    assert_nil Account.resolve_from_description("No counterparty here")
  end

  test "resolve_for_import ignores a household account with a blank account number" do
    Account.create!(name: "Blank number household", person: people(:etienne), account_number: "")

    account = Account.resolve_for_import(account_number: "", description: "No counterparty here", name: "Corner Shop")

    assert_predicate account, :external?
  end

  test "resolve_from_description still finds a numbered household account when a blank-number one is listed first" do
    Account.create!(id: 1, name: "Blank number household", person: people(:etienne), account_number: "")

    description = "Payment via #{accounts(:checking).account_number}"

    assert_equal accounts(:checking), Account.resolve_from_description(description)
  end

  test "resolve_from_description ignores a household account with a blank name" do
    Account.create!(account_number: "NL00BLANK0000000001", name: "", person: people(:etienne))
    Account.where(name: "").update_all(account_number: nil)

    assert_nil Account.resolve_from_description("No counterparty here")
  end

  test "resolve_for_import ignores a household account with a blank name" do
    Account.create!(account_number: "NL00BLANK0000000002", name: "", person: people(:etienne))
    Account.where(name: "").update_all(account_number: nil)

    account = Account.resolve_for_import(account_number: "", description: "No counterparty here", name: "Corner Shop")

    assert_predicate account, :external?
  end

  test "resolve_from_description prefers the household account over an external account with the same name" do
    Account.create!(id: 1, name: accounts(:checking).name)

    assert_equal accounts(:checking), Account.resolve_from_description("Payment to #{accounts(:checking).name}")
  end
end
