# Links Albert Heijn deliveries to the bank payments that confidently paid them
#
# Two things make a payment confident. The bank note names the order number, which is decisive. Or,
# when no payment names it, a single door-card payment falls close to the delivery and is no other
# delivery's candidate too: the amount the bank took rarely equals the mail's total, because empties
# are settled at the door, but it sits within a few days and a small shortfall of it. Anything less
# sure is left unlinked, for a person to confirm.
module Receipt::PaymentMatching
  extend ActiveSupport::Concern

  DOOR_CARD_WINDOW = 3.days
  DOOR_CARD_SHORTFALL_PERCENT = 15
  UNPACKED_SURPLUS_PERCENT = 30

  included do
    # Deliveries no payment is linked to yet, for a person to confirm
    #
    #: () -> ActiveRecord::Relation
    scope :unlinked_deliveries, -> { where.not(order_number: nil).where(payment_id: nil) }
  end

  class_methods do
    # Links every unlinked delivery that has exactly one confident payment, and splits that payment
    # by the basket. Returns the deliveries it linked.
    #
    #: () -> Array[Receipt]
    def link_payments
      deliveries = unlinked_deliveries.order(:issued_on, :id).to_a
      ordered = deliveries.index_with(&:ordered_payments)
      door_card = deliveries.select { |delivery| ordered[delivery].empty? }.index_with(&:door_card_payments)
      contested = door_card.values.flatten.tally.select { |_payment, count| count > 1 }.keys

      deliveries.filter_map do |delivery|
        payment = confident_payment(ordered[delivery], door_card[delivery], contested)
        delivery if payment && delivery.settle_with(payment)
      end
    end

    private

    def confident_payment(ordered, door_card, contested)
      return ordered.first if ordered.one?
      return nil if ordered.any?

      door_card.first if door_card.one? && contested.exclude?(door_card.first)
    end
  end

  # The payments whose bank note names this delivery's order number as a whole token
  #
  # Only the shop's own credits count. The number is matched whole, so `AE732868893` never matches order `73286889`.
  #
  #: () -> Array[Transaction]
  def ordered_payments
    token = /\bAE#{Regexp.escape(order_number)}\b/

    Credit.where.missing(:receipt)
          .where(debitor: Account.where(name: Receipt::SHOP_NAME))
          .where("original_note LIKE :like OR note LIKE :like", like: "%AE#{order_number}%")
          .select { |payment| [ payment.note, payment.original_note ].any? { |note| note.to_s.match?(token) } }
  end

  # The door-card payments close enough to the delivery to have paid it
  #
  # A packed delivery is no dearer than its total. One known only from an order confirmation may be up
  # to 30% above it, because the estimate leaves out Koopzegels and crates.
  #
  # A basket dearer than the payment does not rule it out: crates returned at the door lower the charge.
  #
  #: () -> Array[Transaction]
  def door_card_payments
    Credit.where.missing(:receipt)
          .where(debitor: Account.where(name: Receipt::SHOP_NAME))
          .where(booked_at: door_card_days)
          .where("original_note LIKE 'Pasvolgnr%' OR note LIKE 'Pasvolgnr%'")
          .where("amount * 100 <= :total * :cap AND amount * 100 >= :total * :kept",
                  total: total_amount, cap: ceiling_percent, kept: kept_percent)
          .to_a
  end

  # Takes the payment as this delivery's and splits it when the basket fits, unless another receipt holds it by now
  #
  # The check and the link share one transaction, and SQLite opens each one with `BEGIN IMMEDIATE`,
  # so two links of one payment run one after the other and the second sees the first.
  #
  #: (Transaction payment) -> bool
  def settle_with(payment)
    transaction do
      next false if Receipt.exists?(payment_id: payment.id)

      update!(payment: payment)
      rewrite_payment_splits
      true
    end
  end

  private

  def kept_percent = 100 - DOOR_CARD_SHORTFALL_PERCENT

  def ceiling_percent = packed? ? 100 : 100 + UNPACKED_SURPLUS_PERCENT

  def door_card_days
    (issued_on - DOOR_CARD_WINDOW).beginning_of_day..(issued_on + DOOR_CARD_WINDOW).end_of_day
  end
end
