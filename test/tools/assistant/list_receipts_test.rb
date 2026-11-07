require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ListReceiptsTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "lists receipts newest first with shop, day, total and payment" do
    older = receipts(:albert_heijn_friday)
    newer = Receipt.create!(shop: accounts(:jumbo), issued_on: older.issued_on + 1, total_amount: 800,
      payment: transactions(:uncategorized))

    lines = said(Assistant::ListReceipts.call(server_context: nil)).lines

    assert_includes lines.first, "#{newer.id}: #{newer.issued_on} #{accounts(:jumbo).name} 8.00, payment #"
    assert_includes lines.second, "#{older.id}: #{older.issued_on} Albert Heijn B.V. 50.00, no payment linked"
  end

  test "says when more exist than shown" do
    assert_includes said(Assistant::ListReceipts.call(limit: 1, server_context: nil)), "Showing 1 of 2 receipts"
  end
end
