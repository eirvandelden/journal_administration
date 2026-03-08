# Connects a source transaction (Debit/Credit) to a covering Transfer
#
# Named `source` instead of `transaction` to avoid shadowing
# ActiveRecord::Base#transaction.
class TransactionLink < ApplicationRecord
  belongs_to :source, class_name: "Transaction", foreign_key: :source_transaction_id
  belongs_to :transfer, class_name: "Transaction"

  validates :transfer_id, uniqueness: true
  validate :transfer_must_be_transfer_type
  validate :source_must_not_be_transfer_type

  private

  def transfer_must_be_transfer_type
    return if transfer.blank?

    unless transfer.type == "Transfer"
      errors.add(:transfer, :must_be_transfer)
    end
  end

  def source_must_not_be_transfer_type
    return if source.blank?

    if source.type == "Transfer"
      errors.add(:source, :must_not_be_transfer)
    end
  end
end
