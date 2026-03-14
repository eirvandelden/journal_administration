# Represents a bank account with transactions and categorization
#
# Accounts can be family-owned (samen, etienne, michelle, serena, cosimo, chiara) or external
# (e.g., Albert Heijn, creditors, other banks). The owner enum determines whether
# transactions are debits, credits, or transfers.
class Account < ApplicationRecord
  include Normalizable
  include Resolvable
  include BulkUpdatable
  include Searchable

  searchable_on :name, :account_number

  FAMILY_OWNERS = %w[samen etienne michelle serena cosimo chiara].freeze

  # @!attribute [rw] owner
  #   @return [String] The account owner (samen, etienne, michelle, serena, cosimo, chiara)
  enum :owner, { samen: 0, etienne: 1, michelle: 2, serena: 3, cosimo: 4, chiara: 5 }

  scope :own,      -> { where.not(owner: nil) }
  scope :external, -> { where(owner: nil) }

  has_many :account_aliases, dependent: :destroy

  belongs_to :category, optional: true

  validates :account_number, uniqueness: true, allow_blank: true

  # Returns the 10 most recent transactions involving this account as debitor or creditor
  #
  # @param limit [Integer] Maximum number of transactions to return
  # @return [ActiveRecord::Relation] Transactions ordered by most recent first
  def recent_transactions(limit: 10)
    Transaction
      .includes(:creditor, :debitor, :category)
      .where("debitor_account_id = :id OR creditor_account_id = :id", id: id)
      .order(booked_at: :desc, id: :desc)
      .limit(limit)
  end

  # Returns true when the account is not owned by a family member
  #
  # @return [Boolean]
  def external?
    owner.nil?
  end

  # Returns human-readable string representation of the account
  #
  # @return [String] Account name if present, otherwise account number
  def to_s
    return name unless name.blank?

    account_number
  end
end
