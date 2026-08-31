require "test_helper"

class ReceiptTest < ActiveSupport::TestCase
  test "a receipt adds up what the basket cost" do
    assert_equal BigDecimal("6.47"), receipts(:albert_heijn_friday).basket_total
  end

  test "the payment is split the way the basket divides over the categories" do
    receipt = receipts(:albert_heijn_friday)
    receipt.update!(payment: transactions(:debit_grocery))

    receipt.rewrite_payment_splits

    assert_equal(
      { categories(:groceries) => BigDecimal("2.98"), categories(:household) => BigDecimal("3.49") },
      receipt.payment.explicit_transaction_splits.to_h { |split| [ split.category, split.amount ] }
    )
  end

  test "what the basket does not explain stays with the payment's own category" do
    receipt = receipts(:albert_heijn_friday)
    receipt.update!(payment: transactions(:debit_grocery))

    receipt.rewrite_payment_splits

    remainder = receipt.payment.transaction_splits.find_by(remainder: true)

    assert_equal BigDecimal("43.53"), remainder.amount
    assert_equal categories(:supermarket), remainder.category
  end

  test "splitting again replaces the splits from the previous import" do
    receipt = receipts(:albert_heijn_friday)
    receipt.update!(payment: transactions(:debit_grocery))

    receipt.rewrite_payment_splits
    receipt.rewrite_payment_splits

    assert_equal 2, receipt.payment.explicit_transaction_splits.count
  end

  test "a basket bigger than the payment is not split at all" do
    receipt = receipts(:albert_heijn_friday)
    receipt.update!(payment: transactions(:debit_grocery), total_amount: BigDecimal("50.00"))
    receipt.lines.first.update!(full_amount: BigDecimal("60.00"), discount_amount: 0, paid_amount: BigDecimal("60.00"))

    splits_before = receipt.payment.transaction_splits.map(&:attributes)

    assert_not receipt.rewrite_payment_splits
    assert_equal splits_before, receipt.payment.reload.transaction_splits.map(&:attributes)
  end

  test "a receipt is issued by the shop the groceries came from" do
    assert_equal accounts(:albert_heijn), receipts(:albert_heijn_friday).shop
  end

  test "a receipt keeps the invoice it came from" do
    receipt = receipts(:albert_heijn_friday)
    receipt.invoice.attach(io: StringIO.new("pdf content"), filename: "invoice.pdf", content_type: "application/pdf")

    assert_predicate receipt, :valid?
    assert_predicate receipt.invoice, :attached?
  end

  test "a receipt refuses an invoice that is not a PDF" do
    receipt = receipts(:albert_heijn_friday)
    receipt.invoice.attach(io: StringIO.new("plain text"), filename: "invoice.txt", content_type: "text/plain")

    assert_not receipt.valid?
    assert_includes receipt.errors[:invoice], I18n.t("activerecord.errors.messages.must_be_pdf", locale: :en)
  end

  test "a receipt records which payment settled it" do
    receipt = receipts(:albert_heijn_friday)

    receipt.update!(payment: transactions(:debit_grocery))

    assert_equal transactions(:debit_grocery), receipt.reload.payment
  end

  test "a receipt offers the payments made to that shop around its date" do
    assert_includes receipts(:albert_heijn_friday).fitting_payments, transactions(:debit_grocery)
  end

  test "a receipt offers a payment even when the amount differs, since empties are settled at the door" do
    receipt = receipts(:albert_heijn_friday)
    receipt.update!(total_amount: BigDecimal("119.93"))

    assert_includes receipt.fitting_payments, transactions(:debit_grocery)
  end

  test "a receipt does not offer payments to another shop" do
    receipt = receipts(:albert_heijn_friday)
    elsewhere = Transaction.create!(
      type: "Debit", debitor: accounts(:checking), creditor: accounts(:jumbo),
      amount: receipt.total_amount, booked_at: receipt.issued_on, interest_at: receipt.issued_on
    )

    assert_not_includes receipt.fitting_payments, elsewhere
  end

  test "a receipt does not offer payments booked weeks from the delivery" do
    receipt = receipts(:albert_heijn_friday)
    long_ago = Transaction.create!(
      type: "Debit", debitor: accounts(:checking), creditor: accounts(:albert_heijn),
      amount: receipt.total_amount, booked_at: receipt.issued_on - 30.days,
      interest_at: receipt.issued_on - 30.days
    )

    assert_not_includes receipt.fitting_payments, long_ago
  end

  test "a receipt needs the total the invoice states" do
    receipt = Receipt.new(shop: accounts(:albert_heijn), issued_on: Date.current)

    assert_not receipt.valid?
    assert_includes receipt.errors[:total_amount], "can't be blank"
  end
  test "a category whose products came to nothing is not split" do
    free_type = ProductType.create!(name: "Free samples", category: categories(:housing))
    sample = Product.create!(name: "AH Sample", brand: "AH", product_type: free_type)
    @receipt = receipts(:albert_heijn_friday)
    @receipt.lines.create!(product: sample, quantity: 1, full_amount: 1, discount_amount: 1, paid_amount: 0)
    @receipt.update!(payment: transactions(:debit_grocery))

    assert @receipt.rewrite_payment_splits
    assert_not_includes @receipt.payment.explicit_transaction_splits.map(&:category), categories(:housing)
  end
end
