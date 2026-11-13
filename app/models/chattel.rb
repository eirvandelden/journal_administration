class Chattel < ApplicationRecord
  include Searchable
  include PdfAttachmentValidatable
  include Monetary

  monetary :purchase_price

  searchable_on :name, :brand, :kind, :model_number, :serial_number, :notes

  belongs_to :purchase_transaction, class_name: "Transaction", optional: true

  has_one_attached :warranty_document

  validates :name, presence: true
  validates :purchase_price, comparison: { greater_than: 0 }, allow_nil: true
  validates_pdf_attachment_of :warranty_document

  # How long before a warranty ends the household is told
  WARRANTY_NOTICE = 90.days

  scope :active, -> { where(left_possession_at: nil) }
  scope :left, -> { where.not(left_possession_at: nil) }
  scope :warrantied, -> { where(warranty_expires_at: Time.current..) }
  scope :out_of_warranty, -> { where(warranty_expires_at: ..Time.current) }
  scope :warranty_ending, -> { active.where(warranty_expires_at: Time.current..WARRANTY_NOTICE.from_now) }
  scope :unknown_warranty, -> { active.where(warranty_expires_at: nil) }

  # The brands already recorded, so the same brand is not typed two ways
  #
  # @return [Array<String>]
  #: () -> Array[String]
  def self.brands_in_use
    where.not(brand: [ nil, "" ]).distinct.order(:brand).pluck(:brand)
  end

  #: () -> ActiveSupport::TimeWithZone?
  def purchased_at
    self[:purchased_at] || purchase_transaction&.booked_at
  end

  #: () -> bool
  def under_warranty?
    warranty_expires_at.present? && warranty_expires_at.future?
  end

  #: () -> bool
  def active?
    left_possession_at.nil?
  end

  # Returns the best available warranty or proof-of-purchase document.
  # Prefers the chattel's own warranty_document; falls back to the purchase transaction's proof_of_purchase.
  #
  # @return [ActiveStorage::Attached::One, nil]
  #: () -> ActiveStorage::Attached::One?
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
  #: () -> bool
  def proof_of_purchase?
    warranty_proof.present?
  end
end
