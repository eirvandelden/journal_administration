# Something bought in a shop, as it appears on an invoice line
#
# A product arrives from an invoice knowing only its name and pack size. Its
# brand and product type are filled in by hand afterwards, so a product without
# both is unclassified and still needs attention.
class Product < ApplicationRecord
  PACK_UNITS = { gram: 0, kilogram: 1, millilitre: 2, litre: 3, piece: 4 }.freeze

  belongs_to :product_type, optional: true
  has_many :receipt_lines

  enum :pack_unit, PACK_UNITS

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }

  # The product this name stands for, however it was capitalised, or a new one
  # we know nothing about yet
  def self.resolve_by_name(name)
    find_by("LOWER(name) = ?", name.downcase.strip) || create!(name: name.strip)
  end

  scope :unclassified, -> { where(product_type_id: nil).or(where(brand: [ nil, "" ])) }

  # The brands we already buy from, so a new one is typed only once
  def self.brands_in_use
    where.not(brand: [ nil, "" ]).distinct.order(:brand).pluck(:brand)
  end

  def unclassified? = brand.blank? || product_type.blank?

  # Every time we bought this product, most recent invoice first
  def purchases
    receipt_lines.joins(:receipt).includes(:receipt).order("receipts.issued_on DESC")
  end

  def to_s = name
end
