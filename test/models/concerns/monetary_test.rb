require "test_helper"

class MonetaryTest < ActiveSupport::TestCase
  test "a record refuses text that is not an amount" do
    appropriation = Appropriation.new(amount: "abc")

    appropriation.valid?

    assert_includes appropriation.errors.details[:amount], { error: :not_an_amount }
    assert_includes appropriation.errors[:amount], "is not an amount"
  end

  test "a record accepts 1,50" do
    appropriation = Appropriation.new(amount: "1,50")

    appropriation.valid?

    assert_equal 150, appropriation.amount
    assert_empty appropriation.errors.details[:amount]
  end

  test "a blank amount is blank, not unreadable" do
    appropriation = Appropriation.new(amount: "")

    appropriation.valid?

    assert_not_includes appropriation.errors.details[:amount], { error: :not_an_amount }
  end

  test "an unreadable amount shows only the not an amount message" do
    split = TransactionSplit.new(amount: "abc", financial_transaction: transactions(:debit_bakery))

    split.valid?

    assert_equal [ "is not an amount" ], split.errors[:amount]
  end
end
