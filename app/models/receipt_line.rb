# One product on a grocery invoice, with the pack size as printed that week
#
# The shelf price and what was paid are both kept, so a bonus is visible as the
# difference between them.
class ReceiptLine < ApplicationRecord
  COMPARABLE_UNIT = {
    gram: :kilogram, kilogram: :kilogram,
    millilitre: :litre, litre: :litre,
    piece: :piece
  }.freeze
  PER_COMPARABLE_UNIT = { gram: 1000, kilogram: 1, millilitre: 1000, litre: 1, piece: 1 }.freeze

  belongs_to :receipt
  belongs_to :product

  enum :pack_unit, Product::PACK_UNITS

  validates :quantity, presence: true
  validates :full_amount, presence: true
  validates :discount_amount, presence: true
  validates :paid_amount, presence: true
  validate :paid_amount_follows_from_the_bonus

  def on_bonus? = discount_amount.positive?

  def comparable_unit = COMPARABLE_UNIT[pack_unit&.to_sym]

  def paid_price_per_unit = price_per_comparable_unit(paid_amount)

  def shelf_price_per_unit = price_per_comparable_unit(full_amount)

  private

  def paid_amount_follows_from_the_bonus
    return if [ full_amount, discount_amount, paid_amount ].any?(&:blank?)
    return if paid_amount == full_amount - discount_amount

    errors.add(:paid_amount, :does_not_match_bonus)
  end

  def price_per_comparable_unit(amount)
    return if comparable_quantity.blank? || comparable_quantity.zero?

    (amount / comparable_quantity).round(2)
  end

  def comparable_quantity
    return if pack_amount.blank? || pack_unit.blank?

    quantity * pack_amount / PER_COMPARABLE_UNIT.fetch(pack_unit.to_sym)
  end
end
