require "test_helper"

class AccountTest < ActiveSupport::TestCase
  # -- scopes -----------------------------------------------------------------

  test "own scope returns accounts with an owner" do
    own = Account.own
    assert_includes own, accounts(:checking)
    assert_includes own, accounts(:savings)
    assert_not_includes own, accounts(:albert_heijn)
    assert_not_includes own, accounts(:employer)
  end

  test "external scope returns accounts without an owner" do
    external = Account.external
    assert_includes external, accounts(:albert_heijn)
    assert_includes external, accounts(:employer)
    assert_not_includes external, accounts(:checking)
    assert_not_includes external, accounts(:savings)
  end

  # -- owner enum -------------------------------------------------------------

  test "owner enum defines all family members" do
    expected = { "samen" => 0, "etienne" => 1, "michelle" => 2, "serena" => 3, "cosimo" => 4, "chiara" => 5 }

    assert_equal expected, Account.owners
  end

  test "FAMILY_OWNERS matches owner enum keys" do
    assert_equal Account.owners.keys, Account::FAMILY_OWNERS
  end

  # -- validations ------------------------------------------------------------

  test "account_number must be unique" do
    duplicate = Account.new(account_number: accounts(:checking).account_number)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:account_number], "has already been taken"
  end

  test "account_number allows blank" do
    account = Account.new(name: "No Number")

    assert account.valid?
  end

  # -- associations -----------------------------------------------------------

  class BelongsToAssociationsTest < AccountTest
    test "belongs_to category (optional)" do
      assert_equal categories(:groceries), accounts(:checking).category
    end

    test "category can be nil" do
      assert_nil accounts(:savings).category
      assert accounts(:savings).valid?
    end
  end

  # -- recent_transactions ----------------------------------------------------

  test "recent_transactions returns transactions where account mutation is negative" do
    result = accounts(:checking).recent_transactions

    assert_includes result, transactions(:credit_grocery)
  end

  test "recent_transactions returns transactions where account mutation is positive" do
    result = accounts(:checking).recent_transactions

    assert_includes result, transactions(:debit_salary)
  end

  test "recent_transactions respects the limit parameter" do
    result = accounts(:checking).recent_transactions(limit: 2)

    assert_equal 2, result.count
  end

  test "recent_transactions defaults to a limit of ten" do
    11.times do |index|
      create_double_entry_transaction(
        booked_at: 20.days.from_now + index.minutes,
        category: categories(:supermarket),
        primary_account: accounts(:checking),
        counterparty_account: accounts(:albert_heijn),
        primary_amount: -(10 + index)
      )
    end

    assert_equal 10, accounts(:checking).recent_transactions.count
  end

  test "recent_transactions are ordered by booked_at descending" do
    older = create_double_entry_transaction(
      booked_at: 30.days.from_now,
      category: categories(:supermarket),
      primary_account: accounts(:checking),
      counterparty_account: accounts(:albert_heijn),
      primary_amount: -20
    )
    newer = create_double_entry_transaction(
      booked_at: 31.days.from_now,
      category: categories(:supermarket),
      primary_account: accounts(:checking),
      counterparty_account: accounts(:albert_heijn),
      primary_amount: -30
    )

    result_ids = accounts(:checking).recent_transactions(limit: 2).pluck(:id)

    assert_equal [ newer.id, older.id ], result_ids
  end

  test "recent_transactions break booked_at ties with newest record first" do
    timestamp = 60.days.from_now

    first = create_double_entry_transaction(
      booked_at: timestamp,
      category: categories(:supermarket),
      primary_account: accounts(:checking),
      counterparty_account: accounts(:albert_heijn),
      primary_amount: -60
    )
    second = create_double_entry_transaction(
      booked_at: timestamp,
      category: categories(:supermarket),
      primary_account: accounts(:checking),
      counterparty_account: accounts(:albert_heijn),
      primary_amount: -70
    )

    result_ids = accounts(:checking).recent_transactions(limit: 2).pluck(:id)

    assert_equal [ second.id, first.id ], result_ids
  end

  test "recent_transactions preloads associations used by the view" do
    relation = accounts(:checking).recent_transactions

    assert_includes relation.includes_values, :category
    assert_includes relation.includes_values, { mutations: :account }
  end

  # -- to_s -------------------------------------------------------------------

  test "to_s returns name when present" do
    assert_equal "Gezamenlijke Rekening", accounts(:checking).to_s
  end

  test "to_s returns account_number when name is blank" do
    account = Account.new(account_number: "NL00TEST0000000001", name: "")

    assert_equal "NL00TEST0000000001", account.to_s
  end

  private

  def create_double_entry_transaction(booked_at:, category:, primary_account:, counterparty_account:, primary_amount:)
    transaction = Transaction.new(booked_at: booked_at, interest_at: booked_at, category: category)
    transaction.mutations.build(account: primary_account, amount: primary_amount)
    transaction.mutations.build(account: counterparty_account, amount: -primary_amount)
    transaction.save!
    transaction
  end
end
