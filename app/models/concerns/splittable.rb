# Adds split tracking to transactions
#
# Allows a transaction's amount to be distributed across multiple categories
# via associated TransactionSplit records.
module Splittable
  extend ActiveSupport::Concern

  included do
    has_many :transaction_splits, dependent: :destroy
    validate :amount_must_cover_explicit_splits
    after_save :sync_remainder_split, if: :remainder_split_needs_sync?
  end

  # Explicit user-defined splits, excluding the synthetic remainder row.
  #
  # @return [ActiveRecord::Relation]
  def explicit_transaction_splits = transaction_splits.where(remainder: false)

  # Whether this transaction has any splits
  #
  # @return [Boolean]
  def split? = explicit_transaction_splits.any?

  # Remaining amount not yet allocated to explicit splits
  #
  # @return [BigDecimal]
  def split_balance = amount - explicit_transaction_splits.sum(:amount)

  # Whether the full transaction amount is allocated to splits
  #
  # @return [Boolean]
  def fully_split? = split? && (amount - transaction_splits.sum(:amount)).zero?

  # The portion of the transaction that still has no category assigned.
  #
  # @return [BigDecimal]
  def uncategorized_amount
    uncategorized_splits_amount + untracked_uncategorized_amount
  end

  # Auto-manages the remainder split after explicit splits change
  #
  # Creates, updates, or removes the remainder split so that all splits
  # always sum to the transaction amount. Uses the transaction's original
  # category for the remainder.
  #
  # @return [void]
  def ensure_remainder_split
    explicit_splits = transaction_splits.where(remainder: false)
    return transaction_splits.where(remainder: true).destroy_all if explicit_splits.empty?

    explicit_total = explicit_splits.sum(:amount)
    remaining = amount - explicit_total

    remainder = transaction_splits.find_or_initialize_by(remainder: true)

    if remaining.positive?
      remainder.update!(amount: remaining, category: category)
    else
      remainder.destroy if remainder.persisted?
    end
  end

  # Returns the amount relevant to a category page.
  #
  # Falls back to the full transaction amount when the transaction is matched
  # directly through its primary category.
  #
  # @param category [Category]
  # @return [BigDecimal]
  def amount_for(category:) = split? ? matching_transaction_splits_for(category).sum(:amount) : amount

  # Returns the category label relevant to a category page.
  #
  # Falls back to the primary category when the transaction is not matched
  # through splits.
  #
  # @param category [Category]
  # @return [String, nil]
  def category_name_for(category:)
    return self.category&.to_s unless split?

    matching_transaction_splits_for(category).filter_map { |split| split.category&.to_s }.uniq.to_sentence.presence
  end

  private

  def amount_must_cover_explicit_splits
    return unless amount.present? && split?
    return if explicit_transaction_splits.sum(:amount) <= amount

    errors.add(:amount, :must_cover_splits)
  end

  def uncategorized_splits_amount = transaction_splits.where(category_id: nil).sum(:amount)

  def untracked_uncategorized_amount
    return 0 unless category.blank? || split?

    remaining = amount - transaction_splits.sum(:amount)
    remaining.positive? ? remaining : 0
  end

  def matching_transaction_splits_for(category)
    return TransactionSplit.none if category.blank?

    transaction_splits.where(category_id: category.recent_transaction_category_ids)
  end

  def remainder_split_needs_sync?
    split? && (saved_change_to_amount? || saved_change_to_category_id?)
  end

  def sync_remainder_split = ensure_remainder_split
end
