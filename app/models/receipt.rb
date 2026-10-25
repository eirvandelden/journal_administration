# One grocery invoice, as the shop issued it
#
# The total is the amount the invoice states, which can differ from what the
# basket adds up to: a bag fee or a deposit is charged without being a product.
class Receipt < ApplicationRecord
  include PdfAttachmentValidatable
  include Monetary

  monetary :total_amount

  # How far the bank booking may sit from the invoice date and still be the same delivery
  BOOKING_WINDOW = 7.days

  belongs_to :shop, class_name: "Account"
  belongs_to :payment, class_name: "Transaction", optional: true
  has_many :lines, class_name: "ReceiptLine", dependent: :destroy
  has_one_attached :invoice

  validates :issued_on, presence: true
  validates :total_amount, presence: true
  validates_pdf_attachment_of :invoice
  validate :must_not_repeat_a_filed_receipt, on: :file

  # Files a receipt with its basket in one step, or leaves nothing behind
  #
  # Products are found by name the way the importer finds them, so a name nobody has seen starts unclassified
  #: (
  #|   shop: Account, issued_on: Date, total_amount: Integer,
  #|   lines: Array[{ name: String, quantity: Numeric, full_amount: Integer, discount_amount: Integer }],
  #|   ?order_number: String?
  #| ) -> Receipt
  def self.file(shop:, issued_on:, total_amount:, lines:, order_number: nil)
    receipt = new(shop:, issued_on:, total_amount:, order_number:)

    transaction do
      lines.each { |line| receipt.lines.build(filed_line(line)) }
      raise ActiveRecord::Rollback unless receipt.save(context: :file)
    end
    receipt
  end

  def self.filed_line(line)
    line.slice(:quantity, :full_amount, :discount_amount).merge(
      product: Product.resolve_by_name(line[:name]),
      paid_amount: line[:full_amount] - line[:discount_amount]
    )
  end
  private_class_method :filed_line

  def basket_total = lines.sum(:paid_amount)

  # Whether this payment is big enough to have paid for the basket
  def basket_fits?(payment) = payment.present? && basket_total <= payment.amount

  # Splits the payment the way the basket divides over the accounting categories
  #
  # Refuses, and changes nothing, unless the basket can actually say how the
  # payment divides up: a basket costing more than the payment would not add up,
  # and a basket whose products nobody has classified yet says nothing at all.
  # Wiping the payment's splits on the strength of that would throw away work
  # this receipt never did. A payment charged to an appropriation, whole or in
  # parts, is refused too: rewriting its splits would drop those charges.
  def rewrite_payment_splits
    return false unless basket_fits?(payment)
    return false if payment.charged?
    return false if splittable_totals.empty?

    transaction do
      payment.transaction_splits.destroy_all
      splittable_totals.each do |category, amount|
        payment.transaction_splits.create!(category: category, amount: amount)
      end
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
               .where(booked_at: (issued_on - BOOKING_WINDOW).beginning_of_day..(issued_on + BOOKING_WINDOW).end_of_day)
  end

  private

  def must_not_repeat_a_filed_receipt
    existing = repeated_receipt
    errors.add(:base, :repeats_filed_receipt, receipt: existing.id) if existing
  end

  def repeated_receipt
    Receipt.find_by(shop:, issued_on:, total_amount:) ||
      (Receipt.find_by(order_number:) if order_number.present?)
  end

  # A category whose products all came free of charge is left out: a split of
  # nothing is not a split, and the books reject one.
  def splittable_totals
    paid_per_category.reject { |_category, amount| amount.zero? }
  end

  def paid_per_category
    lines.includes(product: { product_type: :category })
         .filter_map { |line| [ line.category, line.paid_amount ] if line.category }
         .group_by(&:first)
         .transform_values { |pairs| pairs.sum(&:last) }
  end
end
