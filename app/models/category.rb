class Category < ApplicationRecord
  has_many :transactions
  enum direction: %i(debit credit)

  validates :direction, presence: true

  def to_s
    name
  end
end
