# Represents a portion of a transaction allocated to a specific category
#
# Splits allow a transaction's amount to be distributed across multiple
# categories. Each split must have a positive amount, and the total of all
# splits for a transaction must not exceed the transaction's amount.
class TransactionSplit < ApplicationRecord
  belongs_to :financial_transaction, class_name: "Transaction", foreign_key: :transaction_id
  belongs_to :category, optional: true

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :amount_does_not_exceed_balance
  validate :financial_transaction_must_not_be_transfer

  private

  def amount_does_not_exceed_balance
    return unless amount.present? && financial_transaction.present?
    return if remainder?

    available = financial_transaction.split_balance
    available += amount_was.to_d if persisted?

    return if amount <= available

    errors.add(:amount, :exceeds_transaction)
  end

  def financial_transaction_must_not_be_transfer
    return if financial_transaction.blank? || financial_transaction.type != "Transfer"

    errors.add(:financial_transaction, :must_not_be_transfer)
  end
end
