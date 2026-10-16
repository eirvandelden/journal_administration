require "test_helper"

class MoneyFixturesTest < ActiveSupport::TestCase
  test "fixtures hold money in cents" do
    assert_equal 5000, transactions(:debit_grocery).amount
    assert_equal 3000, transaction_splits(:split_grocery_supermarket).amount
    assert_equal 5000, receipts(:albert_heijn_friday).total_amount
    assert_equal 70, receipt_lines(:lays_chips_on_bonus).discount_amount
    assert_equal 4999, Chattel.minimum(:purchase_price)
    assert_equal 20_000, BudgetCategory.minimum(:amount)
    assert_equal 5000, Appropriation.minimum(:amount)
  end
end
