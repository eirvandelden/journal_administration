# Something bought in a shop, as it appears on an invoice line
#
# A product arrives from an invoice knowing only its name and pack size. Its
# brand and product type are filled in by hand afterwards, so a product without
# both is unclassified and still needs attention.
class Product < ApplicationRecord
  PACK_UNITS = { gram: 0, kilogram: 1, millilitre: 2, litre: 3, piece: 4 }.freeze

  belongs_to :product_type, optional: true

  enum :pack_unit, PACK_UNITS

  validates :name, presence: true

  scope :unclassified, -> { where(product_type_id: nil).or(where(brand: [ nil, "" ])) }

  def unclassified? = brand.blank? || product_type.blank?
end
