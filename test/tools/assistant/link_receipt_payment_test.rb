require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::LinkReceiptPaymentTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "links and lists the splits written" do
    text = said(link)

    assert_equal transactions(:debit_grocery), receipts(:albert_heijn_friday).reload.payment
    assert_includes text, "2.98 Groceries"
    assert_includes text, "3.49 Household"
  end

  test "refuses a payment that does not fit and lists the ones that do" do
    response = link(payment: transactions(:uncategorized))

    assert refused_response?(response)
    assert_includes said(response), "#{transactions(:debit_grocery).id}: "
  end

  test "refuses a basket bigger than the payment" do
    transactions(:debit_grocery).transaction_splits.destroy_all
    transactions(:debit_grocery).update!(amount: 500)

    response = link

    assert refused_response?(response)
    assert_includes said(response), "bigger than the payment"
  end

  test "refuses a charged payment" do
    transaction_splits(:split_grocery_bakery).update!(appropriation: appropriations(:birthday_etienne))

    assert_includes said(link), "charged to an appropriation"
  end

  test "links without splitting and names the unclassified products" do
    Product.where(id: receipts(:albert_heijn_friday).lines.select(:product_id)).update_all(product_type_id: nil)

    text = said(link)

    assert_includes text, "AH Naturel Ribbelchips"
    assert_equal transactions(:debit_grocery), receipts(:albert_heijn_friday).reload.payment
  end

  test "links without splitting and says an empty basket has nothing to split" do
    receipts(:albert_heijn_friday).lines.destroy_all

    assert_includes said(link), "nothing to split"
  end

  test "refuses a receipt linked to another payment" do
    receipts(:albert_heijn_friday).update!(payment: transactions(:debit_bakery))

    assert_includes said(link), "unlink it first"
  end

  test "refuses a payment that paid another receipt and changes no split" do
    other = receipts(:albert_heijn_duplicate_monday)
    other.update!(payment: transactions(:debit_grocery))
    before = transactions(:debit_grocery).transaction_splits.pluck(:id, :amount)

    response = link

    assert refused_response?(response)
    assert_includes said(response), "already paid receipt ##{other.id}"
    assert_equal before, transactions(:debit_grocery).transaction_splits.pluck(:id, :amount)
  end

  private

  def link(payment: transactions(:debit_grocery))
    Assistant::LinkReceiptPayment.call(receipt_id: receipts(:albert_heijn_friday).id,
      transaction_id: payment.id, server_context: nil)
  end
end
