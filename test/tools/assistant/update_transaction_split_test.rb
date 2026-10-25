require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::UpdateTransactionSplitTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "changes a part and keeps the remainder" do
    payment = transactions(:debit_grocery)
    part = transaction_splits(:split_grocery_bakery)

    Assistant::UpdateTransactionSplit.call(transaction_id: payment.id, transaction_split_id: part.id,
      amount: 5.00, server_context: nil)

    assert_equal 500, part.reload.amount
    assert_equal 1500, payment.transaction_splits.find_by(remainder: true).amount
  end

  test "refuses a part of another payment" do
    response = Assistant::UpdateTransactionSplit.call(transaction_id: transactions(:uncategorized).id,
      transaction_split_id: transaction_splits(:split_grocery_bakery).id, amount: 1.00, server_context: nil)

    assert refused_response?(response)
  end
end
