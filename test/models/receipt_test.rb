require "test_helper"

class ReceiptTest < ActiveSupport::TestCase
  test "a receipt adds up what the basket cost" do
    assert_equal BigDecimal("2.98"), receipts(:albert_heijn_friday).basket_total
  end

  test "a receipt is issued by the shop the groceries came from" do
    assert_equal accounts(:albert_heijn), receipts(:albert_heijn_friday).shop
  end

  test "a receipt keeps the invoice it came from" do
    receipt = receipts(:albert_heijn_friday)
    receipt.invoice.attach(io: StringIO.new("pdf content"), filename: "invoice.pdf", content_type: "application/pdf")

    assert receipt.valid?
    assert receipt.invoice.attached?
  end

  test "a receipt refuses an invoice that is not a PDF" do
    receipt = receipts(:albert_heijn_friday)
    receipt.invoice.attach(io: StringIO.new("plain text"), filename: "invoice.txt", content_type: "text/plain")

    assert_not receipt.valid?
    assert_includes receipt.errors[:invoice], I18n.t("activerecord.errors.messages.must_be_pdf", locale: :en)
  end

  test "a receipt needs the total the invoice states" do
    receipt = Receipt.new(shop: accounts(:albert_heijn), issued_on: Date.current)

    assert_not receipt.valid?
    assert_includes receipt.errors[:total_amount], "can't be blank"
  end
end
