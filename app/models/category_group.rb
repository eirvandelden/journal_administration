class CategoryGroup < ApplicationRecord
  has_many :category_groups
  has_many :transactions, through: :category

  belongs_to :account, optional: true
end
