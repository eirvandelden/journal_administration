# Represents a person who can own an account or receive an appropriation.
class Person < ApplicationRecord
  has_many :accounts, dependent: :restrict_with_error
  has_many :appropriations, dependent: :restrict_with_error
  has_many :group_memberships, dependent: :restrict_with_error
  has_many :groups, through: :group_memberships

  validates :name, presence: true
  validate :name_key_is_unique
  validate :preserve_transaction_classification
  before_validation :normalize_name_key

  # Whether this person belongs to the household.
  # @return [Boolean]
  def household?
    household
  end

  private

  # Rejects duplicate names using Unicode-aware case folding.
  # @return [void]
  def name_key_is_unique
    return unless name_key.present? && self.class.where(name_key:).where.not(id:).exists?

    errors.add(:name, :taken)
  end

  # Prevents changing account classification when transactions already use it.
  # @return [void]
  def preserve_transaction_classification
    return unless will_save_change_to_household?
    return unless accounts_with_transactions.exists? || groups_with_transactions.any? { |group|
      group_loses_owner? group
    }

    errors.add(:household, :cannot_change_with_transactions)
  end

  # Accounts owned directly by this person with financial history.
  # @return [ActiveRecord::Relation]
  def accounts_with_transactions
    accounts.joins("INNER JOIN transactions ON transactions.debitor_account_id = accounts.id " \
      "OR transactions.creditor_account_id = accounts.id")
  end

  # Groups whose household status this person affects and that have financial history.
  # @return [ActiveRecord::Relation]
  def groups_with_transactions
    groups.joins(:accounts).joins("INNER JOIN transactions ON transactions.debitor_account_id = accounts.id " \
      "OR transactions.creditor_account_id = accounts.id")
  end

  # Whether changing this person's flag changes a group with transaction history.
  # @param group [Group]
  # @return [Boolean]
  def group_loses_owner?(group)
    !group.people.where(household: true).where.not(id:).exists?
  end

  # Stores the Unicode-aware key used by the unique database index.
  # @return [void]
  def normalize_name_key
    self.name_key = name.downcase if name.present?
  end
end
