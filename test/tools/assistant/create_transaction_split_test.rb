require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::CreateTransactionSplitTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "adds a part and keeps the remainder" do
    payment = unsplit_debit

    add(payment, 30.00)

    assert_equal [ 3000 ], payment.explicit_transaction_splits.pluck(:amount)
    assert_equal 2000, payment.transaction_splits.find_by(remainder: true).amount
  end

  test "refuses a part bigger than what is left" do
    response = add(unsplit_debit, 80.00)

    assert refused_response?(response)
    assert_includes said(response), "exceeds the remaining transaction amount"
  end

  test "refuses a transfer" do
    assert_includes said(add(transactions(:transfer_savings), 1.00)), "Transfer"
  end

  private

  def add(payment, amount)
    Assistant::CreateTransactionSplit.call(transaction_id: payment.id, amount: amount, server_context: nil)
  end
end
