require "test_helper"

class ImportableTest < ActiveSupport::TestCase
  test "build_from_import creates a debit transaction for Af direction" do
    row = Importing::ING::Row.new(
      date: DateTime.new(2024, 1, 15),
      initiator_name: "Albert Heijn B.V.",
      our_account_number: accounts(:checking).account_number,
      their_account_number: accounts(:albert_heijn).account_number,
      code: "GT",
      direction: "Af",
      amount: 25.50,
      mutation_kind: "Betaalautomaat",
      description: "Groceries",
      original_balance: "1000.00",
      original_tag: ""
    )

    transaction = Transaction.build_from_import(
      row,
      our_account: accounts(:checking),
      their_account: accounts(:albert_heijn)
    )

    assert_equal accounts(:checking), transaction.creditor
    assert_equal accounts(:albert_heijn), transaction.debitor
    assert_equal 25.50, transaction.amount
    assert_equal "Credit", transaction.type
  end

  test "build_from_import creates a credit transaction for Bij direction" do
    row = Importing::ING::Row.new(
      date: DateTime.new(2024, 1, 15),
      initiator_name: "Werkgever B.V.",
      our_account_number: accounts(:checking).account_number,
      their_account_number: accounts(:employer).account_number,
      code: "OV",
      direction: "Bij",
      amount: 3000.00,
      mutation_kind: "Overschrijving",
      description: "Salary",
      original_balance: "5000.00",
      original_tag: ""
    )

    transaction = Transaction.build_from_import(
      row,
      our_account: accounts(:checking),
      their_account: accounts(:employer)
    )

    assert_equal accounts(:checking), transaction.debitor
    assert_equal accounts(:employer), transaction.creditor
    assert_equal 3000.00, transaction.amount
    assert_equal "Debit", transaction.type
  end

  test "build_from_import sets note from row fields" do
    row = Importing::ING::Row.new(
      date: DateTime.new(2024, 1, 15),
      initiator_name: "Test",
      our_account_number: "NL00TEST",
      their_account_number: "",
      code: "GT",
      direction: "Af",
      amount: 10.00,
      mutation_kind: "Betaalautomaat",
      description: "Some description",
      original_balance: "100.00",
      original_tag: "tag"
    )

    transaction = Transaction.build_from_import(
      row,
      our_account: accounts(:checking),
      their_account: accounts(:unknown)
    )

    assert_includes transaction.note, "Some description"
    assert_includes transaction.note, "GT"
    assert_includes transaction.note, "Betaalautomaat"
  end
end
