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

  # Remaining amount not yet allocated to splits
  #
  # @return [BigDecimal]
  def split_balance = amount - transaction_splits.sum(:amount)

  # Whether the full transaction amount is allocated to splits
  #
  # @return [Boolean]
  def fully_split? = split_balance.zero?
end
