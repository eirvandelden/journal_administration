require "test_helper"

class Assistant::LinkDeliveriesToPaymentsTest < ActiveSupport::TestCase
  test "answers each linked delivery, then the deliveries left over" do
    Receipt.create!(shop: accounts(:albert_heijn), issued_on: Date.new(2026, 8, 28), total_amount: 11_993,
      order_number: "74532780")
    Receipt.create!(shop: accounts(:albert_heijn), issued_on: Date.new(2026, 9, 5), total_amount: 5_000,
      order_number: "999")

    text = Assistant::LinkDeliveriesToPayments.call(server_context: nil).content.first[:text]

    assert_includes text, "Linked order 74532780 to payment ##{transactions(:ordered_grocery).id} of 131.66"
    assert_includes text, "Not linked: Receipt #"
    assert_includes text, "order 999 on 2026-09-05, 50.00 in total"
  end

  test "says so when every delivery is linked" do
    text = Assistant::LinkDeliveriesToPayments.call(server_context: nil).content.first[:text]

    assert_includes text, "Every delivery is linked to a payment."
  end
end
