# Represents a bank account with transactions and categorization
#
# Accounts can be family-owned (samen, etienne, michelle, serena, cosimo, chiara) or external
# (e.g., Albert Heijn, creditors, other banks). The owner enum determines whether
# transactions are debits, credits, or transfers.
class Account < ApplicationRecord
  include Normalizable
  include PaymentProvider
  include Resolvable
  include BulkUpdatable
  include Searchable

  searchable_on :name, :account_number

  LEGACY_OWNERS = {
    "samen" => "Samen",
    "etienne" => "Etienne",
    "michelle" => "Michelle",
    "serena" => "Serena",
    "cosimo" => "Cosimo",
    "chiara" => "Chiara"
  }.freeze

  # @!attribute [rw] owner
  #   @return [String] The account owner (samen, etienne, michelle, serena, cosimo, chiara)
  enum :owner, { samen: 0, etienne: 1, michelle: 2, serena: 3, cosimo: 4, chiara: 5 }

  scope :own, -> {
    where(person_id: Person.where(household: true)).or(
      where(group_id: Group.joins(:people).where(people: { household: true }))
    )
  }
  scope :external, -> { where.not(id: own.select(:id)) }

  has_many :account_aliases, dependent: :destroy

  belongs_to :person, optional: true
  belongs_to :group, optional: true

  belongs_to :category, optional: true

  validates :account_number, uniqueness: true, allow_blank: true
  validate :one_managed_owner
  validate :preserve_transaction_classification
  validate :legacy_owner_is_unchanged
  before_validation :assign_legacy_owner

  before_destroy :check_no_transactions_exist

  # Returns the 10 most recent transactions involving this account as debitor or creditor
  #
  # @param limit [Integer] Maximum number of transactions to return
  # @return [ActiveRecord::Relation] Transactions ordered by most recent first
  def recent_transactions(limit: 10)
    Transaction
      .includes(:creditor, :debitor, :category)
      .where("debitor_account_id = :id OR creditor_account_id = :id", id: id)
      .order(booked_at: :desc, id: :desc)
      .limit(limit)
  end

  # Returns true when the account is not owned by a family member
  #
  # @return [Boolean]
  def external?
    !household_owned?
  end

  # Whether this account belongs to a household person or group.
  # @return [Boolean]
  def household_owned?
    person&.household? || group&.household? || false
  end

  # Returns human-readable string representation of the account
  #
  # @return [String] Account name if present, otherwise account number
  def to_s
    return name unless name.blank?

    account_number
  end

  # Reassigns transactions from any external account whose name exactly matches
  # one of this account's alias patterns to self.
  #
  # @return [Integer] Number of transactions reassigned
  def absorb_transactions_from_aliases
    account_aliases.sum { |a| absorb_transactions_for(a.pattern) }
  end

  private

  # Prevents assigning both a person and a group to one account.
  # @return [void]
  def one_managed_owner
    return unless person_id.present? && group_id.present?

    errors.add(:base, :one_owner_only)
  end

  # Refuses ownership changes that would alter the classification of account history.
  # @return [void]
  def preserve_transaction_classification
    return unless persisted? && (will_save_change_to_person_id? || will_save_change_to_group_id?)
    return unless transactions_exist?

    errors.add(:base, :cannot_reclassify_with_transactions) if previous_household_owned? != household_owned?
  end

  # Whether any transactions use this account.
  # @return [Boolean]
  def transactions_exist?
    Transaction.where("debitor_account_id = :id OR creditor_account_id = :id", id:).exists?
  end

  # Whether the stored managed owner marks this account as household-owned.
  # @return [Boolean]
  def previous_household_owned?
    previous = Account.find(id)
    previous.person&.household? || previous.group&.household? || false
  end

  # Refuses edits to the preserved legacy owner field.
  # @return [void]
  def legacy_owner_is_unchanged
    return unless persisted? && will_save_change_to_owner?

    errors.add(:owner, :readonly)
  end

  # Maps legacy owner values to managed people or groups for existing callers.
  # @return [void]
  def assign_legacy_owner
    return if person_id.present? || group_id.present? || owner.blank?

    name = LEGACY_OWNERS[owner]
    return if name.blank?

    self.group = Group.find_or_create_by!(name:) if owner == "samen"
    self.person = Person.find_or_create_by!(name:, household: true) unless owner == "samen"
    group.group_memberships.find_or_create_by!(person: Person.find_or_create_by!(name: "Etienne", household: true)) if
      owner == "samen"
    group.group_memberships.find_or_create_by!(person: Person.find_or_create_by!(name: "Michelle", household: true)) if
      owner == "samen"
  end

  def check_no_transactions_exist
    return unless Transaction.where("debitor_account_id = :id OR creditor_account_id = :id", id: id).exists?

    errors.add(:base, :has_transactions)
    throw :abort
  end

  # @param pattern [String]
  # @return [Integer] Number of transactions reassigned
  def absorb_transactions_for(pattern)
    duplicates = Account.external.where.not(id: id).where("LOWER(name) = LOWER(?)", pattern)
    debitor_count = Transaction.where(debitor_account_id: duplicates).update_all(debitor_account_id: id)
    creditor_count = Transaction.where(creditor_account_id: duplicates).update_all(creditor_account_id: id)
    debitor_count + creditor_count
  end
end
