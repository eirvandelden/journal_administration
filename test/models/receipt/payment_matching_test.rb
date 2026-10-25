require "test_helper"

class Receipt::PaymentMatchingTest < ActiveSupport::TestCase
  DAY = Time.zone.local(2026, 8, 28, 12)

  test "link_payments links the payment that names the order number" do
    delivery = delivery("74532780", total: 11_993)

    assert_equal [ delivery ], Receipt.link_payments
    assert_equal transactions(:ordered_grocery), delivery.reload.payment
  end

  test "does not match a longer AE number" do
    delivery = delivery("7453278")

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "leaves a delivery with two ordered payments unlinked" do
    delivery = delivery("74532780")
    ordered_payment("Omschrijving: AE74532780 tweede")

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "links an ordered payment smaller than the basket and leaves its splits" do
    delivery = delivery("74532780", paid: 20_000)
    splits_before = transactions(:ordered_grocery).transaction_splits.map(&:attributes)

    assert_equal [ delivery ], Receipt.link_payments
    assert_equal splits_before, transactions(:ordered_grocery).reload.transaction_splits.map(&:attributes)
  end

  test "links a door-card payment on the last day of the window" do
    delivery = delivery("100", total: 10_000)
    payment = door_card_payment(9_500, on: DAY + 3.days)

    assert_equal [ delivery ], Receipt.link_payments
    assert_equal payment, delivery.reload.payment
  end

  test "links the only door-card payment that fits" do
    delivery = delivery("100", total: 10_000)
    payment = door_card_payment(9_500)

    assert_equal [ delivery ], Receipt.link_payments
    assert_equal payment, delivery.reload.payment
  end

  test "ignores a door-card payment more than 15% under the total" do
    delivery = delivery("100", total: 10_000)
    door_card_payment(8_400)

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "ignores a door-card payment above the total" do
    delivery = delivery("100", total: 10_000)
    door_card_payment(10_100)

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "ignores a door-card payment more than 3 days away" do
    delivery = delivery("100", total: 10_000)
    door_card_payment(9_500, on: DAY + 4.days)

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "links a door-card payment smaller than the basket and leaves its splits" do
    delivery = delivery("100", total: 10_000, paid: 9_500)
    payment = door_card_payment(9_000)
    payment.transaction_splits.create!(category: categories(:supermarket), amount: 4_000)
    splits_before = payment.reload.transaction_splits.map(&:attributes)

    assert_equal [ delivery ], Receipt.link_payments
    assert_equal payment, delivery.reload.payment
    assert_equal splits_before, payment.reload.transaction_splits.map(&:attributes)
  end

  test "links a door-card payment charged to an appropriation and keeps its splits" do
    delivery = delivery("100", total: 10_000, paid: 9_000)
    payment = door_card_payment(9_500)
    payment.update!(appropriation: appropriations(:birthday_etienne))

    assert_equal [ delivery ], Receipt.link_payments
    assert_equal appropriations(:birthday_etienne), payment.reload.appropriation
    assert_empty payment.transaction_splits.where.not(appropriation: appropriations(:birthday_etienne))
  end

  test "links a confirmation-only delivery to a door-card payment 20% above its total" do
    delivery = delivery("100", total: 10_000, packed: false)
    payment = door_card_payment(12_000)

    assert_equal [ delivery ], Receipt.link_payments
    assert_equal payment, delivery.reload.payment
  end

  test "ignores a door-card payment more than 30% above a confirmation-only total" do
    delivery = delivery("100", total: 10_000, packed: false)
    door_card_payment(13_100)

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "ignores a door-card payment above a packed delivery's total" do
    delivery = delivery("100", total: 10_000, packed: true)
    door_card_payment(12_000)

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "leaves a delivery with two door-card candidates unlinked" do
    delivery = delivery("100", total: 10_000)
    door_card_payment(9_500)
    door_card_payment(9_700)

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "a door-card payment that fits two deliveries links neither" do
    first = delivery("100", total: 10_000)
    second = delivery("200", total: 9_900)
    door_card_payment(9_600)

    assert_empty Receipt.link_payments
    assert_nil first.reload.payment
    assert_nil second.reload.payment
  end

  test "never door-card matches a delivery that has an ordered payment" do
    delivery = delivery("74532780", total: 13_166)
    ordered_payment("Omschrijving: AE74532780 tweede")
    door_card_payment(13_000)

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "a payment another delivery holds is not linked" do
    holder = delivery("1")
    holder.update!(payment: transactions(:ordered_grocery))
    wanting = delivery("74532780")

    assert_empty Receipt.link_payments
    assert_nil wanting.reload.payment
  end

  test "does not link a payment another receipt took inside the same transaction" do
    wanting = delivery("74532780")
    delivery("2").update!(payment: transactions(:ordered_grocery))

    assert_not wanting.settle_with(transactions(:ordered_grocery))
    assert_nil wanting.reload.payment
  end

  test "ignores a door-card payment to another shop" do
    delivery = delivery("100", total: 10_000)
    door_card_payment(9_500, debitor: accounts(:jumbo))

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "ignores an order-number payment from another shop" do
    delivery = delivery("74532780", total: 11_993)
    transactions(:ordered_grocery).update!(debitor: accounts(:jumbo))

    assert_empty Receipt.link_payments
    assert_nil delivery.reload.payment
  end

  test "unlinked_deliveries lists deliveries without a payment" do
    open = delivery("100")
    delivery("200").update!(payment: transactions(:ordered_grocery))

    assert_equal [ open ], Receipt.unlinked_deliveries.to_a
  end

  private

  def delivery(order_number, total: 11_993, paid: 0, packed: true)
    receipt = Receipt.create!(shop: accounts(:albert_heijn), issued_on: DAY.to_date, total_amount: total,
      order_number: order_number, packed: packed)
    line(receipt, paid) if paid.positive?
    receipt
  end

  def line(receipt, amount)
    product = Product.create!(name: "Mand #{receipt.order_number}")
    receipt.lines.create!(product: product, quantity: 1, full_amount: amount, discount_amount: 0, paid_amount: amount)
  end

  def door_card_payment(amount, on: DAY, debitor: accounts(:albert_heijn))
    note = "Pasvolgnr: 900 06-03-2026 09:58 Transactie: P00448 Term: --- Valutadatum: 06-03-2026"
    Credit.create!(debitor: debitor, creditor: accounts(:checking), amount: amount, booked_at: on, interest_at: on,
      note: note, original_note: note)
  end

  def ordered_payment(note)
    Credit.create!(debitor: accounts(:albert_heijn), creditor: accounts(:checking), amount: 5_000, booked_at: DAY,
      interest_at: DAY, note: note, original_note: note)
  end
end
