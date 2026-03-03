# Represents a financial transaction between accounts
#
# Transactions are single-table inheritance with three types: Credit, Debit, Transfer.
# The type is automatically determined by which accounts are family-owned accounts.
class Transaction < ApplicationRecord
  include Accountable
  include Categorizable
  include Importable

  TYPES = %w[Credit Debit Transfer].freeze

  default_scope { order(booked_at: :desc) }

  belongs_to :debitor, class_name: "Account", foreign_key: "debitor_account_id", optional: true
  belongs_to :creditor, class_name: "Account", foreign_key: "creditor_account_id", optional: true
  belongs_to :category, optional: true
  has_many :chattels, foreign_key: :purchase_transaction_id

  before_validation :determine_debit_credit_or_transfer_type

  validates :type, inclusion: { in: TYPES, message: "%{value} is not a valid type" }, presence: true
  validate :check_transfer_type_through_account_owners

  # Returns an emoji representation of the transaction type
  #
  # @return [String] emoji icon (e.g., "⬇️ 🟥" for Credit)
  def type_icon
    case self.type
    when "Credit"
      "⬇️ 🟥"
    when "Debit"
      "⬆️ 🟩"
    when "Transfer"
      "🔄 ◻️"
    end
  end

  private

  # Determines transaction type based on account ownership
  #
  # Sets the type to Transfer if both accounts are family-owned,
  # Credit if creditor is family-owned, or Debit if debitor is family-owned.
  #
  # @return [void]
  def determine_debit_credit_or_transfer_type
    # is debitor_account owned by us? This is a Debit Transaction!
    # is creditor_account owned by us? This is a Credit Transaction!
    # are both owned by the same owner? This is a Transfer Transaction! (Or a Debit + Credit Transaction)
    return if type.present?
    return self.type = "Transfer" if debitor_is_us? && creditor_is_us?
    return self.type = "Credit" if creditor_is_us?
    self.type        = "Debit" if debitor_is_us?
  end

  def check_transfer_type_through_account_owners
    if type == "Transfer"
      unless debitor_is_us? && creditor_is_us?
        errors.add(:type, "must be Transfer only if both debitor and creditor are family accounts")
      end
    elsif type == "Debit"
      unless debitor_is_us?
        errors.add(:type, "must be Debit only if debitor is a family account")
      end
    elsif type == "Credit"
      unless creditor_is_us?
        errors.add(:type, "must be Credit only if creditor is a family account")
      end
    end
  end
end
