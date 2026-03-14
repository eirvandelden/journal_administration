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

  test "external? returns true when owner is nil" do
    assert_predicate accounts(:albert_heijn), :external?
  end

  test "external? returns false when owner is present" do
    assert_not_predicate accounts(:checking), :external?
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

  test "belongs_to category (optional)" do
    assert_equal categories(:groceries), accounts(:checking).category
  end

  test "category can be nil" do
    assert_nil accounts(:savings).category
    assert accounts(:savings).valid?
  end

  # -- recent_transactions ----------------------------------------------------

  test "recent_transactions returns transactions where account is debitor" do
    result = accounts(:checking).recent_transactions

    assert_includes result, transactions(:debit_grocery)
  end

  test "recent_transactions returns transactions where account is creditor" do
    result = accounts(:checking).recent_transactions

    assert_includes result, transactions(:credit_salary)
  end

  test "recent_transactions respects the limit parameter" do
    result = accounts(:checking).recent_transactions(limit: 2)

    assert_equal 2, result.count
  end

  test "recent_transactions defaults to a limit of ten" do
    11.times do |index|
      Transaction.create!(
        amount: 10 + index,
        booked_at: 20.days.from_now + index.minutes,
        interest_at: 20.days.from_now + index.minutes,
        debitor: accounts(:checking),
        creditor: accounts(:albert_heijn),
        category: categories(:supermarket)
      )
    end

    assert_equal 10, accounts(:checking).recent_transactions.count
  end

  test "recent_transactions are ordered by booked_at descending" do
    older = Transaction.create!(
      amount: 20,
      booked_at: 30.days.from_now,
      interest_at: 30.days.from_now,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )
    newer = Transaction.create!(
      amount: 30,
      booked_at: 31.days.from_now,
      interest_at: 31.days.from_now,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )

    result_ids = accounts(:checking).recent_transactions(limit: 2).pluck(:id)

    assert_equal [ newer.id, older.id ], result_ids
  end

  test "recent_transactions break booked_at ties with newest record first" do
    timestamp = 60.days.from_now

    first = Transaction.create!(
      amount: 60,
      booked_at: timestamp,
      interest_at: timestamp,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )
    second = Transaction.create!(
      amount: 70,
      booked_at: timestamp,
      interest_at: timestamp,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )

    result_ids = accounts(:checking).recent_transactions(limit: 2).pluck(:id)

    assert_equal [ second.id, first.id ], result_ids
  end

  test "recent_transactions preloads associations used by the view" do
    relation = accounts(:checking).recent_transactions

    assert_includes relation.includes_values, :creditor
    assert_includes relation.includes_values, :debitor
    assert_includes relation.includes_values, :category
  end

  # -- to_s -------------------------------------------------------------------

  test "to_s returns name when present" do
    assert_equal "Gezamenlijke Rekening", accounts(:checking).to_s
  end

  test "to_s returns account_number when name is blank" do
    account = Account.new(account_number: "NL00TEST0000000001", name: "")

    assert_equal "NL00TEST0000000001", account.to_s
  end
end
