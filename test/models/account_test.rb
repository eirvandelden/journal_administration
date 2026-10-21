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

  # -- validations ------------------------------------------------------------

  test "refuses the same number twice in one save" do
    account = Account.new(
      name: "Twice",
      account_numbers: 2.times.map { AccountNumber.new(number: "NL00TWIC0000000001") }
    )

    assert_not account.valid?
    assert_not_empty account.errors[:account_numbers]
  end

  test "household_owned? follows linked household people and groups" do
    %i[etienne michelle serena cosimo chiara].each do |name|
      assert_predicate Account.new(person: people(name)), :household_owned?
    end

    assert_predicate accounts(:checking), :household_owned?
    assert_not accounts(:albert_heijn).household_owned?
    assert_not Account.new(person: people(:grandma)).household_owned?
  end

  test "existing individual owners stay linked to their managed people" do
    assert_equal people(:etienne), accounts(:savings).person
    assert_equal "etienne", accounts(:savings).owner
  end

  test "refuses both person and group as owners" do
    account = Account.new(name: "Two owners", person: people(:etienne), group: groups(:samen))

    assert_not account.valid?
    assert_predicate account.errors[:base], :any?
  end

  test "refuses reclassification with transactions" do
    account = accounts(:checking)

    assert_not account.update(person: people(:grandma), group: nil)
    assert_predicate account.reload, :household_owned?
  end

  test "keeps legacy owner when managed owner changes" do
    account = accounts(:savings)

    assert account.update!(person: people(:michelle))
    assert_equal "etienne", account.reload.owner
  end

  test "clearing an outside managed owner keeps its legacy owner without making it household-owned" do
    account = Account.create!(name: "Legacy outside account", owner: :etienne, person: people(:grandma))

    assert account.update!(person: nil)

    assert_predicate account.reload, :external?
    assert_equal "etienne", account.owner
  end

  test "an account may have no number" do
    account = Account.new(name: "No Number")

    assert_predicate account, :valid?
  end

  # -- numbers ----------------------------------------------------------------

  test "Account#numbers lists every number" do
    assert_equal %w[NL00ABNA9999999001 NL00ABNA9999999002],
      accounts(:albert_heijn_duplicate).numbers.sort
  end

  test "Account#numbers is empty without numbers" do
    assert_empty accounts(:unknown).numbers
  end

  test "destroying an account removes its numbers" do
    assert_difference "AccountNumber.count", -1 do
      accounts(:jumbo).destroy
    end
  end

  test "nested attributes add a number" do
    account = accounts(:jumbo)

    account.update!(account_numbers_attributes: [ { number: "NL00JUMB0000000002" } ])

    assert_equal %w[NL00ABNA8888888888 NL00JUMB0000000002], account.reload.numbers.sort
  end

  test "nested attributes remove a number" do
    account = accounts(:albert_heijn_duplicate)
    removed = account_numbers(:albert_heijn_duplicate_first)

    account.update!(account_numbers_attributes: [ { id: removed.id, _destroy: "1" } ])

    assert_equal %w[NL00ABNA9999999002], account.reload.numbers
  end

  test "nested attributes ignore a blank new number" do
    assert_no_difference "AccountNumber.count" do
      accounts(:jumbo).update!(account_numbers_attributes: [ { number: "" } ])
    end
  end

  # -- associations -----------------------------------------------------------

  test "belongs_to category (optional)" do
    assert_equal categories(:groceries), accounts(:checking).category
  end

  test "category can be nil" do
    assert_nil accounts(:savings).category
    assert_predicate accounts(:savings), :valid?
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
        amount: 1000 + index,
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
      amount: 2000,
      booked_at: 30.days.from_now,
      interest_at: 30.days.from_now,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )
    newer = Transaction.create!(
      amount: 3000,
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
      amount: 6000,
      booked_at: timestamp,
      interest_at: timestamp,
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      category: categories(:supermarket)
    )
    second = Transaction.create!(
      amount: 7000,
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

  test "to_s falls back to the first number" do
    account = Account.new(account_numbers: [ AccountNumber.new(number: "NL00TEST0000000001") ], name: "")

    assert_equal "NL00TEST0000000001", account.to_s
  end

  test "to_s falls back to the lowest number however the numbers were added" do
    account = Account.create!(name: "", account_numbers: [ AccountNumber.new(number: "NL00ZZZZ0000000002"),
                                                           AccountNumber.new(number: "NL00AAAA0000000001") ])

    assert_equal "NL00AAAA0000000001", account.reload.to_s
  end

  # -- absorb_transactions_from_aliases ----------------------------------------

  test "absorb_transactions_from_aliases returns the number of transactions reassigned" do
    count = accounts(:albert_heijn).absorb_transactions_from_aliases

    assert_equal 2, count
  end

  class WhenDestroying < ActiveSupport::TestCase
    test "can be destroyed when it has no transactions" do
      assert accounts(:jumbo).destroy
    end

    test "cannot be destroyed when it has debitor transactions" do
      account = Account.create!(name: "Debitor Account", owner: :samen)
      Transaction.create!(
        amount: 1000,
        booked_at: Time.current,
        interest_at: Time.current,
        debitor: account,
        creditor: accounts(:albert_heijn),
        category: categories(:supermarket)
      )

      assert_not account.destroy
      assert_includes account.errors[:base],
        I18n.t("activerecord.errors.models.account.attributes.base.has_transactions")
    end

    test "cannot be destroyed when it has creditor transactions" do
      account = Account.create!(name: "Creditor Account", owner: :samen)
      Transaction.create!(
        amount: 1000,
        booked_at: Time.current,
        interest_at: Time.current,
        debitor: accounts(:albert_heijn),
        creditor: account,
        category: categories(:supermarket)
      )

      assert_not account.destroy
      assert_includes account.errors[:base],
        I18n.t("activerecord.errors.models.account.attributes.base.has_transactions")
    end
  end

  test "managed_owner with an unknown person is invalid instead of failing on save" do
    account = Account.new(name: "Tampered", managed_owner: "person_99999")

    assert_not account.valid?
    assert_not account.save
  end

  test "managed_owner with an unknown group is invalid instead of failing on save" do
    account = Account.new(name: "Tampered", managed_owner: "group_99999")

    assert_not account.valid?
    assert_not account.save
  end
end
