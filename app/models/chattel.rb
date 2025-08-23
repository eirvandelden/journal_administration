class Chattel < ApplicationRecord
  belongs_to :purchase_transaction, class_name: "Transaction", optional: true

  validates :name, presence: true
  validates :purchase_price, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(left_possession_at: nil) }
  scope :left, -> { where.not(left_possession_at: nil) }
  scope :warrantied, -> { where(warranty_expires_at: Time.current..) }
  scope :out_of_warranty, -> { where(warranty_expires_at: ..Time.current)}

  def purchased_at
    self[:purchased_at] || purchase_transaction&.date
  end

  def under_warranty?
    warranty_expires_at.present? && warranty_expires_at.future?
  end

  def active?
    left_possession_at.nil?
  end
end
