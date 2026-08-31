# One product on a grocery invoice
#
# The shelf price and what was paid are both kept, so a bonus is visible as the
# difference between them.
class ReceiptLine < ApplicationRecord
  belongs_to :receipt
  belongs_to :product

  validates :quantity, presence: true
  validates :full_amount, presence: true
  validates :discount_amount, presence: true
  validates :paid_amount, presence: true
  validate :paid_amount_follows_from_the_bonus

  def on_bonus? = discount_amount.positive?

  private

  def paid_amount_follows_from_the_bonus
    return if [ full_amount, discount_amount, paid_amount ].any?(&:blank?)
    return if paid_amount == full_amount - discount_amount

    errors.add(:paid_amount, :does_not_match_bonus)
  end
end
