# Represents a named collection of people that can own an account.
class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :people, through: :group_memberships
  has_many :accounts, dependent: :restrict_with_error

  validates :name, presence: true
  validate :name_key_is_unique
  before_validation :normalize_name_key

  # Whether at least one member belongs to the household.
  # @return [Boolean]
  def household? = people.where(household: true).exists?

  # Accounts whose transactions depend on this group's household status.
  # @return [ActiveRecord::Relation]
  def accounts_with_transactions
    accounts.joins("INNER JOIN transactions ON transactions.debitor_account_id = accounts.id " \
      "OR transactions.creditor_account_id = accounts.id")
  end

  private

  # Rejects duplicate names using Unicode-aware case folding.
  # @return [void]
  def name_key_is_unique
    return unless name_key.present? && self.class.where(name_key:).where.not(id:).exists?

    errors.add(:name, :taken)
  end

  # Stores the Unicode-aware key used by the unique database index.
  # @return [void]
  def normalize_name_key
    self.name_key = name.downcase if name.present?
  end
end
