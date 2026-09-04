# The kind of thing a product is, regardless of who made it
#
# "Naturel chips" covers both the Albert Heijn and the Lay's bag, which is what
# makes them comparable. The category says how groceries of this type are booked.
class ProductType < ApplicationRecord
  # What a month of buying this kind of thing came to
  Totals = Struct.new(:spent, :count, :on_bonus_count)

  belongs_to :category
  has_many :products

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def to_s = name

  # Every purchase of anything of this type, most recent invoice first
  def purchases
    ReceiptLine.joins(:receipt, :product)
               .where(products: { product_type_id: id })
               .includes(:receipt, :product)
               .order("receipts.issued_on DESC")
  end

  # The most recent purchase of each product of this type, so brands can be compared
  def latest_purchase_per_product
    purchases.group_by(&:product).transform_values(&:first)
  end

  # What we spent, how much we bought, and how much of it was on bonus, per calendar month
  def monthly_totals
    purchases.group_by { |purchase| purchase.receipt.issued_on.beginning_of_month }
             .transform_values { |month| totals_for(month) }
  end

  private

  def totals_for(purchases)
    Totals.new(purchases.sum(&:paid_amount), purchases.sum { |purchase| purchase.quantity.to_i },
               purchases.count(&:on_bonus?))
  end
end
