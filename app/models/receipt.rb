# One grocery invoice, as the shop issued it
#
# The total is the amount the invoice states, which can differ from what the
# basket adds up to: a bag fee or a deposit is charged without being a product.
class Receipt < ApplicationRecord
  include PdfAttachmentValidatable

  # How far the bank booking may sit from the invoice date and still be the same delivery
  BOOKING_WINDOW = 7.days

  belongs_to :shop, class_name: "Account"
  belongs_to :payment, class_name: "Transaction", optional: true
  has_many :lines, class_name: "ReceiptLine", dependent: :destroy
  has_one_attached :invoice

  validates :issued_on, presence: true
  validates :total_amount, presence: true
  validates_pdf_attachment_of :invoice

  def basket_total = lines.sum(:paid_amount)

  # Whether this payment is big enough to have paid for the basket
  def basket_fits?(payment) = payment.present? && basket_total <= payment.amount

  # Splits the payment the way the basket divides over the accounting categories
  #
  # Refuses when the basket costs more than the payment: the books would not
  # add up, and scaling the numbers to fit would invent figures.
  def rewrite_payment_splits
    return false unless basket_fits?(payment)

    transaction do
      payment.transaction_splits.destroy_all
      splittable_totals.each { |category, amount|
 payment.transaction_splits.create!(category: category, amount: amount) }
      payment.ensure_remainder_split
    end
    true
  end

  # The payments that could have settled this receipt, for a person to choose between
  #
  # Deliberately not narrowed by amount: empty crates, bottles and cans are
  # settled at the door, so what the bank takes rarely equals the mail's total.
  def fitting_payments
    Transaction.where(type: "Debit", creditor: shop)
               .where(booked_at: (issued_on - BOOKING_WINDOW)..(issued_on + BOOKING_WINDOW))
  end

  private

  # A category whose products all came free of charge is left out: a split of
  # nothing is not a split, and the books reject one.
  def splittable_totals
    paid_per_category.reject { |_category, amount| amount.zero? }
  end

  def paid_per_category
    lines.includes(product: :product_type)
         .filter_map { |line| [ line.product.product_type.category, line.paid_amount ] if line.product.product_type }
         .group_by(&:first)
         .transform_values { |pairs| pairs.sum(&:last) }
  end
end
