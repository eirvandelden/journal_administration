require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::DeleteTransactionTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "deletes a transaction" do
    payment = transactions(:uncategorized)

    Assistant::DeleteTransaction.call(transaction_id: payment.id, server_context: nil)

    assert_not Transaction.exists?(payment.id)
  end

  test "refuses one a chattel was bought with" do
    response = Assistant::DeleteTransaction.call(transaction_id: transactions(:debit_grocery).id,
      server_context: nil)

    assert refused_response?(response)
    assert_includes said(response), "Laptop"
  end
end
