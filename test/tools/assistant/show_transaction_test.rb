require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::ShowTransactionTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "shows parts with ids, charges and the remainder" do
    payment = transactions(:debit_grocery)
    transaction_splits(:split_grocery_bakery).update!(appropriation: appropriations(:birthday_etienne))
    payment.ensure_remainder_split

    text = said(Assistant::ShowTransaction.call(transaction_id: payment.id, server_context: nil))

    assert_includes text, "#{transaction_splits(:split_grocery_supermarket).id}: 30.00 "
    assert_includes text, "charged to Birthday"
    assert_includes text, "(remainder, rebuilt automatically)"
  end

  test "names the receipt it paid" do
    receipts(:albert_heijn_friday).update!(payment: transactions(:debit_grocery))

    text = said(Assistant::ShowTransaction.call(transaction_id: transactions(:debit_grocery).id, server_context: nil))

    assert_includes text, "Paid receipt ##{receipts(:albert_heijn_friday).id}"
  end
end
