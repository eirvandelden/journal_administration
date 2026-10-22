require "test_helper"

class ResolvableTest < ActiveSupport::TestCase
  test "resolve_for_import finds by account number when present" do
    account = Account.resolve_for_import(
      account_number: account_numbers(:checking).number,
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

    assert_equal [ "NL00NEW0000000001" ], account.numbers
  end

  test "resolve_for_import falls back to description matching when no account number" do
    account = Account.resolve_for_import(
      account_number: "",
      description: "Payment via #{account_numbers(:checking).number}",
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
      account_number: account_numbers(:adyen).number,
      description: "Naam: Kruidvat Omschrijving: Payment IBAN: #{account_numbers(:adyen).number}",
      name: "Kruidvat"
    )

    assert_equal accounts(:kruidvat), account
  end

  test "resolve_from_description ignores a household account without a number" do
    Account.create!(name: "Blank number household", person: people(:etienne))

    assert_nil Account.resolve_from_description("No counterparty here")
  end

  test "resolve_for_import ignores a household account without a number" do
    Account.create!(name: "Blank number household", person: people(:etienne))

    account = Account.resolve_for_import(account_number: "", description: "No counterparty here", name: "Corner Shop")

    assert_predicate account, :external?
  end

  test "resolve_from_description still finds a numbered household account when a numberless one is listed first" do
    Account.create!(id: 1, name: "Blank number household", person: people(:etienne))

    description = "Payment via #{account_numbers(:checking).number}"

    assert_equal accounts(:checking), Account.resolve_from_description(description)
  end

  test "resolve_from_description ignores a household account with a blank name" do
    Account.create!(name: "", person: people(:etienne))

    assert_nil Account.resolve_from_description("No counterparty here")
  end

  test "resolve_for_import ignores a household account with a blank name" do
    Account.create!(name: "", person: people(:etienne))

    account = Account.resolve_for_import(account_number: "", description: "No counterparty here", name: "Corner Shop")

    assert_predicate account, :external?
  end

  test "resolve_from_description prefers the household account over an external account with the same name" do
    Account.create!(id: 1, name: accounts(:checking).name)

    assert_equal accounts(:checking), Account.resolve_from_description("Payment to #{accounts(:checking).name}")
  end

  test "resolve_from_description matches any household number" do
    second = AccountNumber.create!(account: accounts(:checking), number: "NL00INGB5555555555")

    account = Account.resolve_from_description("Payment via #{second.number}")

    assert_equal accounts(:checking), account
  end

  test "resolve_from_description ignores numbers of external accounts" do
    assert_nil Account.resolve_from_description("Payment via #{account_numbers(:albert_heijn).number}")
  end

  test "resolve_for_import finds the account by any of its numbers" do
    account = Account.resolve_for_import(
      account_number: account_numbers(:albert_heijn_duplicate_second).number,
      description: "anything",
      name: "anything"
    )

    assert_equal accounts(:albert_heijn_duplicate), account
  end

  class FindOrCreateByNumber < ActiveSupport::TestCase
    test "find_or_create_by_number finds the owner of any number" do
      assert_no_difference "Account.count" do
        assert_equal accounts(:albert_heijn_duplicate),
          Account.find_or_create_by_number(account_numbers(:albert_heijn_duplicate_second).number)
      end
    end

    test "find_or_create_by_number finds the owner when the number is typed with spaces" do
      assert_equal accounts(:albert_heijn), Account.find_or_create_by_number("nl00 abna 9999 999999")
    end

    test "creates an account with the number when unknown" do
      account = nil

      assert_difference [ "Account.count", "AccountNumber.count" ], 1 do
        account = Account.find_or_create_by_number("NL00NEW0000000002")
      end

      assert_equal [ "NL00NEW0000000002" ], account.numbers
    end

    test "falls back to the account that won when the loser looked up before the winner committed" do
      number = "NL00RACE0000000001"
      winner = Account.create!(name: "Parallel winner", account_numbers: [ AccountNumber.new(number:) ])
      lookups = 0
      original = AccountNumber.method(:find_by)
      AccountNumber.define_singleton_method(:find_by) do |*args, **options|
        (lookups += 1) == 1 ? nil : original.call(*args, **options)
      end

      assert_no_difference "Account.count" do
        assert_equal winner, Account.find_or_create_by_number(number)
      end
    ensure
      AccountNumber.singleton_class.remove_method(:find_by)
    end

    test "falls back to the existing account when the unique index rejects a parallel import" do
      number = "NL00RACE0000000002"
      winner = Account.new(name: "Parallel winner", account_numbers: [ AccountNumber.new(number:) ])
      Account.define_singleton_method(:create!) do |*|
        winner.save!
        raise ActiveRecord::RecordNotUnique, "UNIQUE constraint failed: account_numbers.number"
      end

      assert_equal winner, Account.find_or_create_by_number(number)
    ensure
      Account.singleton_class.remove_method(:create!)
    end
  end
end
