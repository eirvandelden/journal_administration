require "test_helper"

class ImportableTest < ActiveSupport::TestCase
  test "build_from_import for Af (debit) gives our account negative mutation" do
    row = ing_row(direction: "Af", amount: 25.50)

    txn = Transaction.build_from_import(
      row,
      our_account:   accounts(:checking),
      their_account: accounts(:albert_heijn)
    )

    our_mutation   = txn.mutations.find { |m| m.account == accounts(:checking) }
    their_mutation = txn.mutations.find { |m| m.account == accounts(:albert_heijn) }

    assert_equal(-25.50, our_mutation.amount)
    assert_equal  25.50, their_mutation.amount
  end

  test "build_from_import for Bij (credit) gives our account positive mutation" do
    row = ing_row(direction: "Bij", amount: 3000.00)

    txn = Transaction.build_from_import(
      row,
      our_account:   accounts(:checking),
      their_account: accounts(:employer)
    )

    our_mutation   = txn.mutations.find { |m| m.account == accounts(:checking) }
    their_mutation = txn.mutations.find { |m| m.account == accounts(:employer) }

    assert_equal  3000.00, our_mutation.amount
    assert_equal(-3000.00, their_mutation.amount)
  end

  test "build_from_import sets note from row fields" do
    row = ing_row(code: "GT", mutation_kind: "Card payment", description: "Some description")

    txn = Transaction.build_from_import(
      row,
      our_account:   accounts(:checking),
      their_account: accounts(:unknown)
    )

    assert_includes txn.note, "Some description"
    assert_includes txn.note, "GT"
    assert_includes txn.note, "Card payment"
  end

  test "build_from_import returns nil for duplicate transfer" do
    # Persist a transaction matching what a second import would produce
    existing_txn = Transaction.new(booked_at: Date.new(2024, 1, 15))
    existing_txn.mutations.build(account: accounts(:checking), amount: -500)
    existing_txn.mutations.build(account: accounts(:savings), amount: 500)
    existing_txn.save!

    row = ing_row(direction: "Af", amount: 500, date: DateTime.new(2024, 1, 15))

    result = Transaction.build_from_import(
      row,
      our_account:   accounts(:checking),
      their_account: accounts(:savings)
    )

    assert_nil result
  end

  test "build_from_import does not deduplicate against external accounts" do
    row = ing_row(direction: "Af", amount: 25.50, date: DateTime.new(2024, 1, 15))

    txn = Transaction.build_from_import(
      row,
      our_account:   accounts(:checking),
      their_account: accounts(:albert_heijn)
    )

    assert_not_nil txn
  end

  test "build_from_import handles nil counterparty account without raising" do
    row = ing_row(direction: "Af", amount: 25.50)

    txn = nil
    assert_nothing_raised do
      txn = Transaction.build_from_import(
        row,
        our_account:   accounts(:checking),
        their_account: nil
      )
    end

    assert_not_nil txn
    assert_equal 2, txn.mutations.size
  end

  private

  def ing_row(direction: "Af", amount: 10.00, date: DateTime.new(2024, 1, 15),
              code: "GT", mutation_kind: "Card payment", description: "Test",
              initiator_name: "Albert Heijn B.V.")
    Importing::ING::Row.new(**ing_row_attributes(direction, amount, date, code, mutation_kind, description, initiator_name))
  end

  def ing_row_attributes(direction, amount, date, code, mutation_kind, description, initiator_name)
    base_ing_row_attributes(code, mutation_kind, description).merge(
      date: date,
      initiator_name: initiator_name,
      direction: direction,
      amount: amount
    )
  end

  def base_ing_row_attributes(code, mutation_kind, description)
    {
      our_account_number: accounts(:checking).account_number,
      their_account_number: accounts(:albert_heijn).account_number,
      code: code,
      mutation_kind: mutation_kind,
      description: description,
      original_balance: "1000.00",
      original_tag: ""
    }
  end
end
