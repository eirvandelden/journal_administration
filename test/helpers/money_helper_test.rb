require "test_helper"

class MoneyHelperTest < ActionView::TestCase
  test "cents_to_currency renders 150 as it rendered 1.5" do
    assert_equal number_to_currency(BigDecimal("1.5")), cents_to_currency(150)
    assert_equal "$1.50", cents_to_currency(150)
  end

  test "passes options through" do
    assert_equal "€1,234.56", cents_to_currency(123_456, unit: "€")
    assert_equal "-€0.05", cents_to_currency(-5, unit: "€")
  end

  test "keeps nil" do
    assert_nil cents_to_currency(nil)
  end

  test "cents_field_value formats with the locale separator" do
    assert_equal "1,50", cents_field_value(Transaction.new(amount: 150), :amount, separator: ",")
    assert_equal "1234,56", cents_field_value(Transaction.new(amount: 123_456), :amount, separator: ",")
  end

  test "formats with a dot for number fields" do
    assert_equal "0.70", cents_field_value(BudgetCategory.new(amount: 70), :amount, separator: ".")
  end

  test "returns the text a user typed after a failed save" do
    transaction = Transaction.new(amount: "abc")

    assert_equal "abc", cents_field_value(transaction, :amount, separator: ",")
  end

  test "keeps a blank field blank" do
    assert_nil cents_field_value(Transaction.new, :amount, separator: ",")
  end
end
