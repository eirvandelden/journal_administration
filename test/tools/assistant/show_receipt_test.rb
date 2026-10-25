require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ShowReceiptTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "shows the lines with product ids and the fitting payments" do
    receipt = receipts(:albert_heijn_friday)

    text = said(Assistant::ShowReceipt.call(receipt_id: receipt.id, server_context: nil))

    assert_includes text, "product ##{products(:dreft_dishwashing_liquid).id} Dreft afwasmiddel"
    assert_includes text, "#{transactions(:debit_grocery).id}: "
  end

  test "refuses an unknown receipt" do
    assert refused_response?(Assistant::ShowReceipt.call(receipt_id: 0, server_context: nil))
  end
end
