class Chattel < ApplicationRecord
  include Searchable
  include PdfAttachmentValidatable

  searchable_on :name, :kind, :model_number, :serial_number, :notes

  belongs_to :purchase_transaction, class_name: "Transaction", optional: true

  has_one_attached :warranty_document

  validates :name, presence: true
  validates :purchase_price, numericality: { greater_than: 0 }, allow_nil: true
  validates_pdf_attachment_of :warranty_document

  scope :active, -> { where(left_possession_at: nil) }
  scope :left, -> { where.not(left_possession_at: nil) }
  scope :warrantied, -> { where(warranty_expires_at: Time.current..) }
  scope :out_of_warranty, -> { where(warranty_expires_at: ..Time.current) }
  scope :unknown_warranty, -> { active.where(warranty_expires_at: nil) }

  def purchased_at
    self[:purchased_at] || purchase_transaction&.booked_at
  end

  def under_warranty?
    warranty_expires_at.present? && warranty_expires_at.future?
  end

  def active?
    left_possession_at.nil?
  end

  # Returns the best available warranty or proof-of-purchase document.
  # Prefers the chattel's own warranty_document; falls back to the purchase transaction's proof_of_purchase.
  #
  # @return [ActiveStorage::Attached::One, nil]
  def warranty_proof
    if warranty_document.attached?
      warranty_document
    elsif purchase_transaction&.proof_of_purchase&.attached?
      purchase_transaction.proof_of_purchase
    end
  end

  # Returns true when any proof-of-purchase or warranty document is available.
  #
  # @return [Boolean]
  def proof_of_purchase?
    warranty_proof.present?
  end
end
