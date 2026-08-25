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

  test "a receipt links to the invoice it came from" do
    @receipt.invoice.attach(
      io: StringIO.new("pdf content"), filename: "invoice.pdf", content_type: "application/pdf"
    )

    get receipt_path(@receipt)

    assert_response :success
    assert_select "a", text: I18n.t("receipts.basket.view_invoice", locale: :en)
  end
end
