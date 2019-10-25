class Category < ApplicationRecord
  DIRECTIONS = %i(debit credit)
  has_many :transactions
  enum direction: DIRECTIONS

  validates :direction, presence: true

  def to_s
    name
  end
end
