require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::FileReceiptTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "files a receipt and lists its lines" do
    response = file(lines: [ line("Brood", full_amount: 2.5), line("Melk") ])

    assert_not refused_response?(response)
    assert_includes said(response), "Brood"
    assert_includes said(response), "Melk"
    assert_equal 2, Receipt.order(:id).last.lines.count
  end

  test "refuses an unknown shop" do
    assert_includes said(file(shop_id: 0)), "No account #0 exists"
  end

  test "refuses one of our own accounts as the shop" do
    response = file(shop_id: accounts(:checking).id)

    assert refused_response?(response)
    assert_includes said(response), "one of our own accounts"
  end

  test "refuses an order number already filed and names that receipt" do
    receipts(:albert_heijn_friday).update!(order_number: "AH-9")

    assert_includes said(file(order_number: "AH-9")), "##{receipts(:albert_heijn_friday).id}"
  end

  test "refuses an amount with a fraction of a cent" do
    assert_includes said(file(total_amount: 1.005)), "at most two decimals"
  end

  test "refuses a day it cannot read" do
    assert_includes said(file(issued_on: "next Monday")), "Write days as 2026-08-01"
  end

  test "names the receipt it repeats" do
    existing = receipts(:albert_heijn_friday)

    response = file(issued_on: existing.issued_on.to_s, total_amount: 50.00)

    assert refused_response?(response)
    assert_includes said(response), "##{existing.id}"
  end

  private

  def file(**changes)
    Assistant::FileReceipt.call(**{ shop_id: accounts(:albert_heijn).id, issued_on: "2026-09-05",
      total_amount: 3.00, lines: [ line("Brood") ], server_context: nil }.merge(changes))
  end
end
