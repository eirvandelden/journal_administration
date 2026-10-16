# One bank account number held by an Account
#
# A number belongs to one account only. Spaces and case do not count, so "nl46 ingb 0702" and
# "NL46INGB0702" are the same number. The unique index backs up the validation.
class AccountNumber < ApplicationRecord
  belongs_to :account, inverse_of: :account_numbers

  normalizes :number, with: ->(number) { number.gsub(/\s+/, "").upcase }

  validates :number, presence: true
  validate :number_not_taken_by_another_account

  # @return [String]
  def to_s
    number
  end

  private

  def number_not_taken_by_another_account
    owner = AccountNumber.where(number: number).where.not(id: id).includes(:account).first&.account
    return if number.blank? || owner.nil? || owner == account

    errors.add(:number, :taken_by, account: owner.to_s)
  end
end
