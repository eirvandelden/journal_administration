require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::DeleteReceiptTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "deletes the receipt and its lines and says the splits stay" do
    receipt = receipts(:albert_heijn_friday)

    text = said(Assistant::DeleteReceipt.call(receipt_id: receipt.id, server_context: nil))

    assert_not Receipt.exists?(receipt.id)
    assert_not ReceiptLine.exists?(receipt_id: receipt.id)
    assert_includes text, "splits already written"
  end

  test "refuses an unknown receipt" do
    assert refused_response?(Assistant::DeleteReceipt.call(receipt_id: 0, server_context: nil))
  end
end
