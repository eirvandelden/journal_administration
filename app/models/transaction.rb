# Transaction model holds all information for a trnansaction.
# The owner of the debitor account determins the type of Transaction: Debit or Credit.
class Transaction < ApplicationRecord
  TYPES = %w[Credit Debit Transfer].freeze

  belongs_to :debitor, class_name: "Account", foreign_key: "debitor_account_id", optional: true
  belongs_to :creditor, class_name: "Account", foreign_key: "creditor_account_id", optional: true
  belongs_to :category, optional: true

  has_many :transaction_groups, foreign_key: :parent_id
  has_many :transactions, through: :transaction_groups, source: :related#, inverse_of: :parent

  has_one :transaction_group, foreign_key: "related_id"
  has_one :parent, through: :transaction_group

  before_validation :determine_debit_credit_or_transfer_type

  # validates_associated :debitor

  # rubocop:disable Style/FormatStringToken
  validates :type, inclusion: { in: TYPES, message: "%{value} is not a valid type" }, presence: true
  # rubocop:enable Style/FormatStringToken

  def debitor_is_us?
    debitor&.owner&.in? Account::FAMILY_OWNERS
  end

  def creditor_is_us?
    creditor&.owner&.in? Account::FAMILY_OWNERS
  end

  private

  def determine_debit_credit_or_transfer_type
    # is debitor_account owned by us? This is a Debit Transaction!
    # is creditor_account owned by us? This is a Credit Transaction!
    # are both owned by the same owner? This is a Transfer Transaction! (Or a Debit + Credit Transaction)
    return if type.present?
    return self.type = "Transfer" if debitor_is_us? && creditor_is_us?
    return self.type = "Credit" if creditor_is_us?
    return self.type = "Debit" if debitor_is_us?
  end
end
