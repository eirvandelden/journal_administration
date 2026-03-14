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

  # Searches for unlinked Transfer transactions by description and/or amount
  #
  # Returns up to 20 results ordered by date, excluding already-linked transfers.
  # Both params are optional and combined with AND when both present.
  #
  # @param query [String, nil] Matches note, creditor name, or debitor name
  # @param amount [String, nil] Exact amount match
  # @return [ActiveRecord::Relation<Transaction>]
  def searchable_transfers(query: nil, amount: nil)
    return Transaction.none if query.blank? && amount.blank?

    scope = Transaction.unscoped
      .where(type: "Transfer")
      .where.missing(:reverse_transaction_links)
      .where.not(id: linked_transfer_ids)
      .joins("LEFT JOIN accounts AS creditors ON creditors.id = transactions.creditor_account_id")
      .joins("LEFT JOIN accounts AS debitors ON debitors.id = transactions.debitor_account_id")
      .includes(:creditor)
      .order(booked_at: :desc)
      .limit(20)

    if query.present?
      sanitized = "%#{Transaction.sanitize_sql_like(query.strip)}%"
      scope = scope.where(
        "transactions.note LIKE ? OR creditors.name LIKE ? OR debitors.name LIKE ?",
        sanitized, sanitized, sanitized
      )
    end

    scope = scope.where(amount: amount.to_d) if amount.present?
    scope
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
