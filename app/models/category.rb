class Category < ApplicationRecord
  DIRECTIONS = %i(debit credit)
  enum direction: DIRECTIONS

  has_many :transactions
  has_many :secondaries, class_name: "Category",
  foreign_key: "parent_category_id"

  belongs_to :parent_category, class_name: "Category", optional: true

  scope :parents, -> { where(parent_category_id: nil) }

  validates :direction, presence: true

  def to_s
    if parent_category.present?
      "#{parent_category.name} - #{name}"
    else
      name
    end
  end
end
