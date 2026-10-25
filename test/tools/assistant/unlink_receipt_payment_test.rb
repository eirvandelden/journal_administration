require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::UnlinkReceiptPaymentTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "unlinks and says the splits stay" do
    receipt = receipts(:albert_heijn_friday)
    receipt.update!(payment: transactions(:debit_grocery))

    text = said(Assistant::UnlinkReceiptPayment.call(receipt_id: receipt.id, server_context: nil))

    assert_nil receipt.reload.payment
    assert_includes text, "splits already written stay"
  end

  test "says when nothing was linked" do
    text = said(Assistant::UnlinkReceiptPayment.call(receipt_id: receipts(:albert_heijn_friday).id,
      server_context: nil))

    assert_includes text, "was not linked"
  end
end
