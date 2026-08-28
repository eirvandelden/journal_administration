require "test_helper"

class ReceiptsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:member)
    @receipt = receipts(:albert_heijn_friday)
  end

  test "the receipts page lists the invoices we have" do
    get receipts_path

    assert_response :success
    assert_select "tbody td", text: accounts(:albert_heijn).name
    assert_select "tbody td", text: ApplicationController.helpers.number_to_currency(@receipt.total_amount)
  end

  test "the receipts page links each invoice to its own page" do
    get receipts_path

    assert_response :success
    assert_select "a[href=?]", receipt_path(@receipt)
  end

  test "a receipt shows what was in the basket" do
    get receipt_path(@receipt)

    assert_response :success
    assert_select "h2", text: I18n.t("receipts.basket.heading", locale: :en)
    assert_select "td", text: products(:ah_ribbelchips).name
    assert_select "td", text: products(:dreft_dishwashing_liquid).name
  end

  test "a receipt says which payment settled it" do
    @receipt.update!(payment: transactions(:debit_grocery))

    get receipt_path(@receipt)

    assert_response :success
    assert_select "a[href=?]", transaction_path(transactions(:debit_grocery))
  end

  test "a receipt that nothing has settled says so" do
    get receipt_path(@receipt)

    assert_response :success
    assert_select "p", text: /#{Regexp.escape(I18n.t("receipts.show.not_settled", locale: :en))}/
  end

  test "a receipt shows the invoice total next to what the basket adds up to" do
    get receipt_path(@receipt)

    assert_response :success
    assert_select "dd", text: ApplicationController.helpers.number_to_currency(@receipt.total_amount)
    assert_select "dd", text: ApplicationController.helpers.number_to_currency(@receipt.basket_total)
  end

  test "an unsettled receipt offers the payments that could have settled it" do
    get receipt_path(@receipt)

    assert_response :success
    assert_select "form[action=?]", receipt_payment_link_path(@receipt)
    assert_select "input[value=?]", transactions(:debit_grocery).id.to_s
  end

  test "choosing a payment settles the receipt and splits it by the basket" do
    post receipt_payment_link_path(@receipt), params: { receipt: { payment_id: transactions(:debit_grocery).id } }

    assert_redirected_to receipt_path(@receipt)
    assert_equal transactions(:debit_grocery), @receipt.reload.payment
    assert_equal(
      { categories(:groceries) => BigDecimal("2.98"), categories(:household) => BigDecimal("3.49") },
      @receipt.payment.explicit_transaction_splits.to_h { |split| [ split.category, split.amount ] }
    )
  end

  test "a receipt that is already settled offers no picker" do
    @receipt.update!(payment: transactions(:debit_grocery))

    get receipt_path(@receipt)

    assert_response :success
    assert_select "form[action=?]", receipt_payment_link_path(@receipt), count: 0
  end

  test "a receipt no payment could have settled says so" do
    @receipt.update!(issued_on: 1.year.from_now.to_date)

    get receipt_path(@receipt)

    assert_response :success
    assert_select "p", text: /#{Regexp.escape(I18n.t("receipts.show.no_candidates", locale: :en))}/
    assert_select "form[action=?]", receipt_payment_link_path(@receipt), count: 0
  end

  test "a basket costing more than the payment leaves the payment's splits alone" do
    @receipt.lines.first.update!(full_amount: BigDecimal("60.00"), discount_amount: 0, paid_amount: BigDecimal("60.00"))
    splits_before = transactions(:debit_grocery).transaction_splits.map(&:attributes)

    post receipt_payment_link_path(@receipt), params: { receipt: { payment_id: transactions(:debit_grocery).id } }

    assert_redirected_to receipt_path(@receipt)
    assert_equal splits_before, transactions(:debit_grocery).reload.transaction_splits.map(&:attributes)
  end

  test "a receipt links to the invoice it came from" do
    @receipt.invoice.attach(
      io: StringIO.new("pdf content"), filename: "invoice.pdf", content_type: "application/pdf"
    )

    get receipt_path(@receipt)

    assert_response :success
    assert_select "a", text: I18n.t("receipts.basket.view_invoice", locale: :en)
  end
end
