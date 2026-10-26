require "test_helper"

class Assistant::ListUnlinkedDeliveriesTest < ActiveSupport::TestCase
  test "lists unlinked deliveries oldest first" do
    later = delivery("2", Date.new(2026, 9, 5))
    earlier = delivery("1", Date.new(2026, 8, 28))

    text = Assistant::ListUnlinkedDeliveries.call(server_context: nil).content.first[:text]

    assert_equal [ earlier, later ].map { |receipt| "Receipt ##{receipt.id}" }, text.lines.map { |line|
 line[/Receipt #\d+/] }
  end

  test "says so when there is none" do
    text = Assistant::ListUnlinkedDeliveries.call(server_context: nil).content.first[:text]

    assert_equal "Every delivery is linked to a payment.", text
  end

  private

  def delivery(order_number, day)
    Receipt.create!(shop: accounts(:albert_heijn), issued_on: day, total_amount: 1_000, order_number: order_number)
  end
end
