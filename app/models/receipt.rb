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

  validates :issued_on, :total_amount, presence: true
  validates_pdf_attachment_of :invoice

  def basket_total = lines.sum(:paid_amount)

  # The one payment that fits this receipt, or nothing when it is not the only one
  def matching_payment
    fitting = fitting_payments.limit(2).to_a

    fitting.first if fitting.one?
  end

  private

  def fitting_payments
    Transaction.where(type: "Debit", creditor: shop, amount: total_amount)
               .where(booked_at: (issued_on - BOOKING_WINDOW)..(issued_on + BOOKING_WINDOW))
  end
end
