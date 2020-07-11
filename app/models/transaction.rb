# Transaction model holds all information for a trnansaction.
# The owner of the debitor account determins the type of Transaction: Debit or Credit.
class Transaction < ApplicationRecord
  TYPES = %w[Credit Debit Transfer].freeze
  belongs_to :debitor, class_name: 'Account', foreign_key: 'debitor_account_id', optional: true
  belongs_to :creditor, class_name: 'Account', foreign_key: 'creditor_account_id', optional: true
  belongs_to :category, optional: true

  before_validation :determine_debit_credit_or_transfer_type

  # validates_associated :debitor

  validates :type, inclusion: { in: TYPES, message: "#{value} is not a valid type" }, presence: true
  validate :check_transfer_type_through_account_owners

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
    return self.type = 'Transfer' if debitor_is_us? && creditor_is_us?
    return self.type = 'Credit' if creditor_is_us?
    return self.type = 'Debit' if debitor_is_us?
  end

  def check_transfer_type_through_account_owners
    false # TODO: change this to work
    # return errors.add(:type, "must be Transfer if debitor and creditor is us") if type == 'Transfer' && debitor_is_us? && creditor_is_us?
    # return errors.add(:type, "must be Debit if debitor is us") if type == 'Debit' && debitor_is_us?
    # return errors.add(:type, "must be Credit if creditor is us") if type == 'Credit' && creditor_is_us?
  end
end
