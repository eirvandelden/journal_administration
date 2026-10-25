require "test_helper"
require_relative "../test_helpers/assistant_requests"
require_relative "../test_helpers/assistant_tool_calls"

class AssistantTransactionSplitsTest < ActionDispatch::IntegrationTest
  include AssistantRequests
  include AssistantToolCalls

  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
  end

  test "two parts leave the rest of the payment in a remainder split" do
    payment = unsplit_debit

    ask_assistant("create_transaction_split", transaction_id: payment.id, amount: 30.00,
      category_id: categories(:groceries).id)
    ask_assistant("create_transaction_split", transaction_id: payment.id, amount: 12.50,
      category_id: categories(:household).id)

    assert_equal [ 3000, 1250 ], payment.explicit_transaction_splits.order(:id).pluck(:amount)
    assert_equal 750, payment.transaction_splits.find_by(remainder: true).amount
  end

  test "a part bigger than what is left of the payment is refused with the books' reason" do
    answer = ask_assistant("create_transaction_split", transaction_id: transactions(:uncategorized).id, amount: 30.00)

    assert_includes answer, "exceeds the remaining transaction amount"
    assert_not transactions(:uncategorized).split?
  end

  test "a transfer cannot be split" do
    assert refused?("create_transaction_split", transaction_id: transactions(:transfer_savings).id, amount: 10.00)
    assert_includes ask_assistant("create_transaction_split", transaction_id: transactions(:transfer_savings).id,
      amount: 10.00), "Transfer"
  end

  test "replacing the parts of a charged payment is refused and changes nothing" do
    payment = transactions(:debit_grocery)
    transaction_splits(:split_grocery_bakery).update!(appropriation: appropriations(:birthday_etienne))
    before = payment.transaction_splits.order(:id).pluck(:id, :amount)

    assert refused?("replace_transaction_splits", transaction_id: payment.id,
      splits: [ { amount: 10.00, category_id: categories(:groceries).id } ])

    assert_equal before, payment.transaction_splits.order(:id).pluck(:id, :amount)
  end

  test "replacing the parts swaps the whole set" do
    payment = transactions(:debit_grocery)

    ask_assistant("replace_transaction_splits", transaction_id: payment.id,
      splits: [ { amount: 20.00, category_id: categories(:groceries).id, note: "fruit" },
                { amount: 5.00, category_id: categories(:household).id } ])

    assert_equal [ 2000, 500 ], payment.explicit_transaction_splits.order(:id).pluck(:amount)
    assert_equal 2500, payment.transaction_splits.find_by(remainder: true).amount
  end

  test "a replacement with one bad part changes nothing" do
    payment = transactions(:debit_grocery)
    before = payment.transaction_splits.order(:id).pluck(:id, :amount)

    answer = ask_assistant("replace_transaction_splits", transaction_id: payment.id,
      splits: [ { amount: 20.00 }, { amount: 500.00 } ])

    assert_includes answer, "exceeds the remaining transaction amount"
    assert_equal before, payment.transaction_splits.order(:id).pluck(:id, :amount)
  end
end
