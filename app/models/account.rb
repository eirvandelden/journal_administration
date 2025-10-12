class Account < ApplicationRecord
  FAMILY_OWNERS = %w[samen etienne michelle serena cosimo chiara].freeze
  enum :owner, {:samen=>0, :etienne=>1, :michelle=>2, :serena=>3, :cosimo=>4, :chiara=>5}

  belongs_to :category, optional: true

  validates :account_number, uniqueness: true, allow_blank: true

  def to_s
    return name unless name.blank?

    account_number
  end
end
