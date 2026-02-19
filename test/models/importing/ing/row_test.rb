require "test_helper"

class Importing::ING::RowTest < ActiveSupport::TestCase
  test "parse returns nil for header row" do
    csv_row = ["Datum", "Naam / Omschrijving", "Rekening", "Tegenrekening",
               "Code", "Af Bij", "Bedrag (EUR)", "Mutatiesoort", "Mededelingen",
               "Saldo na mutatie", "Tag"]

    assert_nil Importing::ING::Row.parse(csv_row)
  end

  test "parse creates a Row from a valid CSV row" do
    csv_row = ["20240115", "Albert Heijn", "NL54INGB0671255150", "NL00ABNA9999999999",
               "GT", "Af", "25,50", "Betaalautomaat", "Groceries", "1000,00", "tag1"]

    row = Importing::ING::Row.parse(csv_row)

    assert_not_nil row
    assert_equal "Albert Heijn B.V.", row.initiator_name
    assert_equal "NL54INGB0671255150", row.our_account_number
    assert_equal "NL00ABNA9999999999", row.their_account_number
    assert_equal "GT", row.code
    assert_equal "Af", row.direction
    assert_equal 25.50, row.amount
    assert_equal "Betaalautomaat", row.mutation_kind
    assert_equal "Groceries", row.description
  end

  test "debit? returns true when direction is Af" do
    row = build_row(direction: "Af")

    assert row.debit?
    assert_not row.credit?
  end

  test "credit? returns true when direction is Bij" do
    row = build_row(direction: "Bij")

    assert row.credit?
    assert_not row.debit?
  end

  test "note combines description, code, and mutation_kind" do
    row = build_row(description: "Test desc", code: "GT", mutation_kind: "Betaalautomaat")

    assert_equal "Test desc\nGT\nBetaalautomaat", row.note
  end

  test "amount converts comma decimal separator to proper decimal" do
    csv_row = ["20240115", "Test", "NL00TEST", "", "GT", "Af", "1.250,75",
               "Overschrijving", "Test", "1000,00", ""]

    row = Importing::ING::Row.parse(csv_row)

    assert_equal 1250.75, row.amount
  end

  test "initiator_name is normalized" do
    csv_row = ["20240115", "AH Amsterdam", "NL00TEST", "", "GT", "Af", "10,00",
               "Betaalautomaat", "Test", "1000,00", ""]

    row = Importing::ING::Row.parse(csv_row)

    assert_equal "Albert Heijn B.V.", row.initiator_name
  end

  private

  def build_row(overrides = {})
    defaults = {
      date: DateTime.new(2024, 1, 15),
      initiator_name: "Test",
      our_account_number: "NL00TEST",
      their_account_number: "NL00OTHER",
      code: "GT",
      direction: "Af",
      amount: 10.00,
      mutation_kind: "Betaalautomaat",
      description: "Test",
      original_balance: "1000.00",
      original_tag: ""
    }

    Importing::ING::Row.new(**defaults.merge(overrides))
  end
end
