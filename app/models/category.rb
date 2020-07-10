class Category < ApplicationRecord
  DIRECTIONS = %i(debit credit)
  enum direction: DIRECTIONS

  has_many :transactions
  has_many :secondaries, class_name: "Category",
  foreign_key: "parent_category_id"

  belongs_to :parent, class_name: "Category", optional: true

  validates :direction, presence: true

  def to_s
    name
  end
end
