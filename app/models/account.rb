class Account < ApplicationRecord
  belongs_to :category

  enum owner: %i(samen etienne michelle serena)
end
