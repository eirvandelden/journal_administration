# Represents a bank account with transactions and categorization
#
# Accounts can be family-owned (samen, etienne, michelle, serena, cosimo, chiara) or external
# (e.g., Albert Heijn, creditors, other banks). The owner enum determines whether
# transactions are debits, credits, or transfers.
class Account < ApplicationRecord
  include Normalizable
  include Resolvable
  include BulkUpdatable

  FAMILY_OWNERS = %w[samen etienne michelle serena cosimo chiara].freeze

  # @!attribute [rw] owner
  #   @return [String] The account owner (samen, etienne, michelle, serena, cosimo, chiara)
  enum :owner, { samen: 0, etienne: 1, michelle: 2, serena: 3, cosimo: 4, chiara: 5 }

  belongs_to :category, optional: true

  validates :account_number, uniqueness: true, allow_blank: true

  # Returns human-readable string representation of the account
  #
  # @return [String] Account name if present, otherwise account number
  def to_s
    return name unless name.blank?

    account_number
  end
end
