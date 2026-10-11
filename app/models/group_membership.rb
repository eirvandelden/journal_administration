# Connects one person to one group.
class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :person

  validates :person_id, uniqueness: { scope: :group_id }
  validate :preserve_transaction_classification
  before_destroy :preserve_transaction_classification

  private

  # Prevents changing group household ownership when transactions already use it.
  # @return [void]
  def preserve_transaction_classification
    return unless household_change_affects_transaction?

    errors.add(:base, :cannot_change_with_transactions)
    throw :abort if destroyed_by_association.nil? && !new_record?
  end

  # Whether this membership change changes ownership of an account with history.
  # @return [Boolean]
  def household_change_affects_transaction?
    return false unless group&.accounts_with_transactions&.exists?

    group.household? != household_after_change?
  end

  # Whether the group has a household person after this change.
  # @return [Boolean]
  def household_after_change?
    remaining = group.people.where(household: true).where.not(id: person_id)
    return remaining.exists? unless new_record?

    remaining.exists? || person.household?
  end
end
