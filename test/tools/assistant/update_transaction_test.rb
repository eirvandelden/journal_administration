require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::UpdateTransactionTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "changes amount, days, category and note" do
    payment = transactions(:uncategorized)

    Assistant::UpdateTransaction.call(transaction_id: payment.id, amount: 3.10, booked_on: "2026-09-01",
      interest_on: "2026-09-02", category_id: categories(:groceries).id, note: "Corrected", server_context: nil)

    payment.reload

    assert_equal [ 310, Date.new(2026, 9, 1), Date.new(2026, 9, 2), categories(:groceries), "Corrected" ],
      [ payment.amount, payment.booked_at.to_date, payment.interest_at.to_date, payment.category, payment.note ]
  end

  test "refuses an amount below its parts" do
    response = Assistant::UpdateTransaction.call(transaction_id: transactions(:debit_grocery).id, amount: 10.00,
      server_context: nil)

    assert refused_response?(response)
    assert_includes said(response), "must cover the total of the explicit splits"
  end
end
