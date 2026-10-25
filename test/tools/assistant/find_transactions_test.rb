require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::FindTransactionsTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "filters by type, category, account and period" do
    text = said(find(type: "Transfer", category_id: categories(:transfer).id, account_id: accounts(:savings).id,
      start_date: 5.days.ago.to_date.to_s, end_date: Date.current.to_s))

    assert_includes text, "#{transactions(:transfer_savings).id}: Transfer"
    assert_not_includes text, "Debit"
  end

  test "lists only uncategorized ones when asked" do
    text = said(find(uncategorized: true))

    assert_includes text, "#{transactions(:uncategorized).id}: Debit"
    assert_not_includes text, "#{transactions(:transfer_savings).id}: "
  end

  test "searches note and amount" do
    assert_includes said(find(query: "Groceries at AH")), "#{transactions(:debit_grocery).id}: "
    assert_includes said(find(query: "50.00")), "#{transactions(:debit_grocery).id}: "
  end

  test "refuses a period that ends before it starts" do
    response = find(start_date: "2026-09-02", end_date: "2026-09-01")

    assert refused_response?(response)
    assert_includes said(response), "cannot end before it starts"
  end

  private

  def find(**filters) = Assistant::FindTransactions.call(**filters, server_context: nil)
end
