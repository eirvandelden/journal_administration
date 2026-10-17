require "test_helper"

class ReceiptLineTest < ActiveSupport::TestCase
  test "a line where the bonus does not explain the price paid is refused" do
    line = ReceiptLine.new(
      receipt: receipts(:albert_heijn_friday),
      product: products(:lays_ribbelchips),
      quantity: 1,
      full_amount: 219,
      discount_amount: 70,
      paid_amount: 219
    )

    assert_not line.valid?
    expected = I18n.t("activerecord.errors.models.receipt_line.attributes.paid_amount.does_not_match_bonus",
locale: :en)

    assert_includes line.errors[:paid_amount], expected
  end

  test "paid amount follows from the bonus in cents" do
    line = ReceiptLine.new(
      receipt: receipts(:albert_heijn_friday), product: products(:lays_ribbelchips),
      quantity: 1, full_amount: 219, discount_amount: 70, paid_amount: 149
    )

    assert_predicate line, :valid?
  end

  test "a line bought on bonus knows it was" do
    assert_predicate receipt_lines(:lays_chips_on_bonus), :on_bonus?
    assert_not receipt_lines(:ah_chips).on_bonus?
  end
  test "a line cannot claim the shop charged more than the shelf price" do
    line = ReceiptLine.new(
      receipt: receipts(:albert_heijn_friday), product: products(:lays_ribbelchips),
      quantity: 1, full_amount: 100, discount_amount: -500, paid_amount: 600
    )

    assert_not line.valid?
    assert_includes line.errors[:discount_amount], "must be greater than or equal to 0"
  end

  test "a line knows the category its groceries are booked to" do
    assert_equal categories(:groceries), receipt_lines(:ah_chips).category
  end

  test "a line whose product nobody classified books to nothing" do
    receipt_lines(:ah_chips).product.update!(product_type: nil)

    assert_nil receipt_lines(:ah_chips).category
  end
end
