# Adds split tracking to transactions
#
# Allows a transaction's amount to be distributed across multiple categories
# via associated TransactionSplit records.
module Splittable
  extend ActiveSupport::Concern

  included do
    has_many :transaction_splits, dependent: :destroy
  end

  # Whether this transaction has any splits
  #
  # @return [Boolean]
  def split? = transaction_splits.any?

  # Remaining amount not yet allocated to explicit splits
  #
  # @return [BigDecimal]
  def split_balance = amount - transaction_splits.where(remainder: false).sum(:amount)

  # Whether the full transaction amount is allocated to splits
  #
  # @return [Boolean]
  def fully_split? = split_balance.zero?

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
  def amount_for(category:)
    matching_amount = matching_splits_for(category).sum(&:amount)
    matching_amount.zero? ? amount : matching_amount
  end

  # Returns the category label relevant to a category page.
  #
  # Falls back to the primary category when the transaction is not matched
  # through splits.
  #
  # @param category [Category]
  # @return [String, nil]
  def category_name_for(category:)
    names = matching_splits_for(category).filter_map { |split| split.category&.to_s }.uniq
    names.empty? ? self.category&.to_s : names.to_sentence
  end

  private

  def matching_splits_for(category)
    return [] if category.blank?

    transaction_splits.select { |split| category.recent_transaction_category_ids.include?(split.category_id) }
  end
end
