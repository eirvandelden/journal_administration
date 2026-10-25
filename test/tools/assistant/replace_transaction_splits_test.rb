require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ReplaceTransactionSplitsTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "replaces the parts and lists them" do
    payment = transactions(:debit_grocery)

    text = said(replace(payment, [ { amount: 20.00, category_id: categories(:groceries).id } ]))

    assert_equal [ 2000 ], payment.explicit_transaction_splits.pluck(:amount)
    assert_includes text, "20.00 Groceries"
  end

  test "refuses a charged payment" do
    payment = transactions(:debit_grocery)
    transaction_splits(:split_grocery_bakery).update!(appropriation: appropriations(:birthday_etienne))

    response = replace(payment, [ { amount: 20.00 } ])

    assert refused_response?(response)
    assert_includes said(response), "charged"
  end

  test "refuses an unknown category" do
    assert_includes said(replace(transactions(:debit_grocery), [ { amount: 1.00, category_id: 0 } ])),
      "No category #0 exists"
  end

  private

  def replace(payment, splits)
    Assistant::ReplaceTransactionSplits.call(transaction_id: payment.id, splits: splits, server_context: nil)
  end
end
