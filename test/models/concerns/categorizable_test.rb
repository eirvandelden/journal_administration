require "test_helper"

class CategorizableTest < ActiveSupport::TestCase
  test "assign_category_from_type assigns Transfer category for Transfer type" do
    transaction = Transaction.new(type: "Transfer")

    transaction.assign_category_from_type

    assert_equal categories(:transfer), transaction.category
  end

  test "assign_category_from_type assigns debitor category for Credit type" do
    transaction = Transaction.new(type: "Credit", debitor: accounts(:albert_heijn))

    transaction.assign_category_from_type

    assert_equal accounts(:albert_heijn).category, transaction.category
  end

  test "assign_category_from_type assigns creditor category for Debit type" do
    transaction = Transaction.new(type: "Debit", creditor: accounts(:albert_heijn))

    transaction.assign_category_from_type

    assert_equal accounts(:albert_heijn).category, transaction.category
  end

  test "assign_category_from_type assigns nil when debitor has no category" do
    transaction = Transaction.new(type: "Credit", debitor: accounts(:unknown))

    transaction.assign_category_from_type

    assert_nil transaction.category
  end
end
