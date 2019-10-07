class Account < ApplicationRecord
  enum owner: %i(samen etienne michelle serena)

  belongs_to :category, optional: true

  validates :account_number, uniqueness: true, allow_blank: true
end
