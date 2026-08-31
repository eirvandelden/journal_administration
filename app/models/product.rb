# Something bought in a shop, as it appears on an invoice line
#
# A product arrives from an invoice knowing only its name. Its brand and
# product type are filled in by hand afterwards, so a product without
# both is unclassified and still needs attention.
class Product < ApplicationRecord
  belongs_to :product_type, optional: true
  has_many :receipt_lines

  validates :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }

  # The product this name stands for, however it was capitalised, or a new one
  # we know nothing about yet
  def self.resolve_by_name(name)
    wanted = name.strip

    find_by("LOWER(name) = ?", wanted.downcase) || find_by(id: id_named_like(wanted)) || create!(name: wanted)
  end

  # The database folds only A to Z, so a stored name holding an accented capital
  # needs Ruby's own idea of lower case to be recognised.
  def self.id_named_like(wanted)
    pluck(:id, :name).find { |_id, name| name.downcase == wanted.downcase }&.first
  end
  private_class_method :id_named_like

  scope :unclassified, -> { where(product_type_id: nil).or(where("TRIM(COALESCE(brand, '')) = ''")) }

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
