class Category < ApplicationRecord
  has_many :transactions

  def to_s
    name
  end
end
