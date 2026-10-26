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
    assert_select "tbody td", text: ApplicationController.helpers.cents_to_currency(@receipt.total_amount)
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
    @receipt.update!(payment: transactions(:credit_grocery))

    get receipt_path(@receipt)

    assert_response :success
    assert_select "a[href=?]", transaction_path(transactions(:credit_grocery))
  end

  test "a receipt that nothing has settled says so" do
    get receipt_path(@receipt)

    assert_response :success
    assert_select "p", text: /#{Regexp.escape(I18n.t("receipts.show.not_settled", locale: :en))}/
  end

  test "a receipt shows the invoice total next to what the basket adds up to" do
    get receipt_path(@receipt)

    assert_response :success
    assert_select "dd", text: ApplicationController.helpers.cents_to_currency(@receipt.total_amount)
    assert_select "dd", text: ApplicationController.helpers.cents_to_currency(@receipt.basket_total)
  end

  test "an unsettled receipt offers the payments that could have settled it" do
    get receipt_path(@receipt)

    assert_response :success
    assert_select "#payment-picker"
    assert_select "input[value=?]", transactions(:credit_grocery).id.to_s
  end

  test "choosing a payment settles the receipt and splits it by the basket" do
    post receipt_payment_link_path(@receipt), params: { receipt: { payment_id: transactions(:credit_grocery).id } }

    assert_redirected_to receipt_path(@receipt)
    assert_equal transactions(:credit_grocery), @receipt.reload.payment
    assert_equal(
      { categories(:groceries) => 298, categories(:household) => 349 },
      @receipt.payment.explicit_transaction_splits.to_h { |split| [ split.category, split.amount ] }
    )
  end

  test "a receipt that is already settled offers no picker" do
    @receipt.update!(payment: transactions(:credit_grocery))

    get receipt_path(@receipt)

    assert_response :success
    assert_select "#payment-picker", count: 0
  end

  test "a receipt no payment could have settled says so" do
    @receipt.update!(issued_on: 1.year.from_now.to_date)

    get receipt_path(@receipt)

    assert_response :success
    assert_select "p", text: /#{Regexp.escape(I18n.t("receipts.show.no_candidates", locale: :en))}/
    assert_select "#payment-picker", count: 0
  end

  test "a basket costing more than the payment leaves the payment's splits alone" do
    @receipt.lines.first.update!(full_amount: 6000, discount_amount: 0, paid_amount: 6000)
    splits_before = transactions(:credit_grocery).transaction_splits.map(&:attributes)

    post receipt_payment_link_path(@receipt), params: { receipt: { payment_id: transactions(:credit_grocery).id } }

    assert_redirected_to receipt_path(@receipt)
    assert_equal splits_before, transactions(:credit_grocery).reload.transaction_splits.map(&:attributes)
  end

  test "a basket costing more than the payment does not settle the receipt either" do
    @receipt.lines.first.update!(full_amount: 6000, discount_amount: 0, paid_amount: 6000)

    post receipt_payment_link_path(@receipt), params: { receipt: { payment_id: transactions(:credit_grocery).id } }

    assert_nil @receipt.reload.payment
  end

  test "a receipt cannot be settled against a charged payment" do
    payment = Transaction.create!(
      type: "Credit", debitor: accounts(:albert_heijn), creditor: accounts(:checking), amount: 5000,
      booked_at: @receipt.issued_on, interest_at: @receipt.issued_on, appropriation: appropriations(:birthday_etienne)
    )

    post receipt_payment_link_path(@receipt), params: { receipt: { payment_id: payment.id } }

    assert_redirected_to receipt_path(@receipt)
    assert_nil @receipt.reload.payment
    assert_empty payment.transaction_splits
    assert_predicate flash[:alert], :present?
  end

  test "a receipt settled by mistake can be unsettled" do
    @receipt.update!(payment: transactions(:credit_grocery))

    delete receipt_payment_link_path(@receipt)

    assert_redirected_to receipt_path(@receipt)
    assert_nil @receipt.reload.payment
  end

  test "a receipt links to the invoice it came from" do
    @receipt.invoice.attach(
      io: StringIO.new("pdf content"), filename: "invoice.pdf", content_type: "application/pdf"
    )

    get receipt_path(@receipt)

    assert_response :success
    assert_select "a", text: I18n.t("receipts.basket.view_invoice", locale: :en)
  end
  test "settling a delivery of unclassified products keeps the payment's own categories" do
    @receipt.lines.each { |line| line.product.update!(product_type: nil) }
    splits_before = transactions(:credit_grocery).transaction_splits.map(&:attributes)

    post receipt_payment_link_path(@receipt), params: { receipt: { payment_id: transactions(:credit_grocery).id } }

    assert_equal transactions(:credit_grocery), @receipt.reload.payment
    assert_equal splits_before, transactions(:credit_grocery).reload.transaction_splits.map(&:attributes)
    assert_equal I18n.t("receipts.payment_links.create.nothing_to_split", locale: :en), flash[:notice]
  end

  test "the index has a title bar h1 and every cell a data-label" do
    get receipts_path

    assert_select "main > header > h1", count: 1
    assert_select "table[data-stack] tbody td:not([data-label])", count: 0
  end
end
