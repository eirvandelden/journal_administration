# The kind of thing a product is, regardless of who made it
#
# "Naturel chips" covers both the Albert Heijn and the Lay's bag, which is what
# makes them comparable. The category says how groceries of this type are booked.
class ProductType < ApplicationRecord
  belongs_to :category

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def to_s = name
end
