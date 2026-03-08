# Adds transfer linking to transactions
#
# Allows source transactions (Debit/Credit) to be linked to Transfer
# transactions that cover them, with auto-suggestions and balance tracking.
module Linkable
  extend ActiveSupport::Concern

  included do
    has_many :transaction_links, foreign_key: :source_transaction_id, dependent: :destroy
    has_many :linked_transfers, through: :transaction_links, source: :transfer

    has_many :reverse_transaction_links, class_name: "TransactionLink",
      foreign_key: :transfer_id, dependent: :destroy
    has_many :linked_sources, through: :reverse_transaction_links, source: :source
  end

  # Finds Transfer transactions that likely cover this transaction
  #
  # Matches on same amount within a ±5 day window, excluding already-linked ones.
  #
  # @return [ActiveRecord::Relation<Transaction>]
  def suggested_transfers
    return Transaction.none if type == "Transfer"

    Transaction.unscoped
      .where(type: "Transfer")
      .where.missing(:reverse_transaction_links)
      .where(amount: amount)
      .where(booked_at: (booked_at - 5.days)..(booked_at + 5.days))
      .where.not(id: linked_transfer_ids)
      .order(booked_at: :desc)
  end

  # Remaining amount not yet covered by linked transfers
  #
  # @return [BigDecimal] 0 when fully covered, positive when underpull
  def link_balance
    amount - linked_transfers.sum(:amount)
  end

  # Whether linked transfers fully cover this transaction's amount
  #
  # @return [Boolean]
  def fully_covered?
    link_balance.zero?
  end

  # Whether this transaction has any links
  #
  # @return [Boolean]
  def linked?
    transaction_links.any?
  end
end
