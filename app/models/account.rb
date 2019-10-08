class Account < ApplicationRecord
  FAMILY_OWNERS = %w(samen etienne michelle serena)
  enum owner: %i(samen etienne michelle serena)

  belongs_to :category, optional: true

  validates :account_number, uniqueness: true, allow_blank: true
end
