# Represents a portion of a transaction allocated to a specific category
#
# Splits allow a transaction's amount to be distributed across multiple
# categories. Each split must have a positive amount, and the total of all
# splits for a transaction must not exceed the transaction's amount.
class TransactionSplit < ApplicationRecord
  include Chargeable

  belongs_to :financial_transaction, class_name: "Transaction", foreign_key: :transaction_id
  belongs_to :category, optional: true

  delegate :booked_at, to: :financial_transaction

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :amount_does_not_exceed_balance
  validate :financial_transaction_must_not_be_transfer
  validate :financial_transaction_must_not_be_charged_as_a_whole
  validate :remainder_must_not_be_charged

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

  # Refuses a part of a payment already charged whole, so the same euro is not charged twice
  def financial_transaction_must_not_be_charged_as_a_whole
    return if financial_transaction&.appropriation_id.blank?

    errors.add(:financial_transaction, :charged_as_a_whole)
  end

  # The remainder is rebuilt whenever the explicit parts change, which would drop its charge
  def remainder_must_not_be_charged
    errors.add(:appropriation, :remainder) if remainder? && appropriation_id.present?
  end
end
