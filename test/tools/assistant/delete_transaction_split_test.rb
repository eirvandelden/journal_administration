require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::DeleteTransactionSplitTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "removes a part and keeps the remainder" do
    payment = transactions(:debit_grocery)

    remove(payment, transaction_splits(:split_grocery_bakery).id)

    assert_equal [ 3000 ], payment.explicit_transaction_splits.pluck(:amount)
    assert_equal 2000, payment.transaction_splits.find_by(remainder: true).amount
  end

  test "refuses a charged part" do
    part = transaction_splits(:split_grocery_bakery)
    part.update!(appropriation: appropriations(:birthday_etienne))

    response = remove(transactions(:debit_grocery), part.id)

    assert refused_response?(response)
    assert_includes said(response), "Part ##{part.id} is charged to"
    assert TransactionSplit.exists?(part.id)
  end

  test "cannot find the remainder split" do
    payment = transactions(:debit_grocery)
    payment.ensure_remainder_split
    remainder = payment.transaction_splits.find_by!(remainder: true)

    assert refused_response?(remove(payment, remainder.id))
    assert TransactionSplit.exists?(remainder.id)
  end

  private

  def remove(payment, split_id)
    Assistant::DeleteTransactionSplit.call(transaction_id: payment.id, transaction_split_id: split_id,
      server_context: nil)
  end
end
