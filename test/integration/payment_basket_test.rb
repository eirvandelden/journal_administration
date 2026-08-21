require "test_helper"

class PaymentBasketTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:member)
    @payment = transactions(:debit_grocery)
    receipts(:albert_heijn_friday).update!(payment: @payment)
  end

  test "the payment shows the basket it paid for" do
    get transaction_path(@payment)

    assert_response :success
    assert_select "h2", text: I18n.t("receipts.basket.heading", locale: :en)
    assert_select "td", text: "AH Naturel Ribbelchips"
    assert_select "td", text: "Dreft afwasmiddel"
  end

  test "the payment links to the invoice the shop issued" do
    receipts(:albert_heijn_friday).invoice.attach(
      io: StringIO.new("pdf content"), filename: "invoice.pdf", content_type: "application/pdf"
    )

    get transaction_path(@payment)

    assert_response :success
    assert_select "a", text: I18n.t("receipts.basket.view_invoice", locale: :en)
  end

  test "a payment without a receipt shows no basket" do
    get transaction_path(transactions(:debit_bakery))

    assert_response :success
    assert_select "h2", text: I18n.t("receipts.basket.heading", locale: :en), count: 0
  end
end
