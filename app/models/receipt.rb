# One grocery invoice, as the shop issued it
#
# The total is the amount the invoice states, which can differ from what the
# basket adds up to: a bag fee or a deposit is charged without being a product.
class Receipt < ApplicationRecord
  include PdfAttachmentValidatable

  belongs_to :shop, class_name: "Account"
  has_many :lines, class_name: "ReceiptLine", dependent: :destroy
  has_one_attached :invoice

  validates :issued_on, :total_amount, presence: true
  validates_pdf_attachment_of :invoice

  def basket_total = lines.sum(:paid_amount)
end
