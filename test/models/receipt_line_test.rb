require "test_helper"

class ReceiptLineTest < ActiveSupport::TestCase
  test "a line where the bonus does not explain the price paid is refused" do
    line = ReceiptLine.new(
      receipt: receipts(:albert_heijn_friday),
      product: products(:lays_ribbelchips),
      quantity: 1,
      full_amount: BigDecimal("2.19"),
      discount_amount: BigDecimal("0.70"),
      paid_amount: BigDecimal("2.19")
    )

    assert_not line.valid?
    assert_includes line.errors[:paid_amount], I18n.t("activerecord.errors.models.receipt_line.attributes.paid_amount.does_not_match_bonus", locale: :en)
  end

  test "a line bought on bonus knows it was" do
    assert receipt_lines(:lays_chips_on_bonus).on_bonus?
    assert_not receipt_lines(:ah_chips).on_bonus?
  end

  test "a line knows what a kilo of it cost" do
    assert_equal BigDecimal("4.97"), receipt_lines(:ah_chips).paid_price_per_unit
  end

  test "a bonus line also knows what a kilo would have cost without the bonus" do
    line = receipt_lines(:lays_chips_on_bonus)

    assert_equal BigDecimal("4.97"), line.paid_price_per_unit
    assert_equal BigDecimal("7.30"), line.shelf_price_per_unit
  end

  test "a line names the unit its price can be compared in" do
    assert_equal :kilogram, receipt_lines(:ah_chips).comparable_unit
  end
end
