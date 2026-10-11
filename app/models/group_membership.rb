# Connects one person to one group.
class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :person

  validates :person_id, uniqueness: { scope: :group_id }
  validate :preserve_transaction_classification, on: :create
  validate :preserve_transaction_classification_on_update, on: :update
  before_destroy :preserve_transaction_classification_on_destroy

  private

  # Prevents adding a person to a group that owns accounts with transactions
  # when that would change the group's household status.
  # @return [void]
  def preserve_transaction_classification
    return unless joining_changes_household?

    errors.add(:base, :cannot_change_with_transactions)
  end

  # Whether adding the new membership reclassifies the destination group.
  # @return [Boolean]
  def joining_changes_household?
    after = household_without(group, person_id) || person&.household?
    household_change_affects_transaction?(group, after)
  end

  # Whether the group keeps a household person once the given person is excluded.
  # @return [Boolean]
  def household_without(owner, excluded_person_id)
    owner.present? && owner.people.where(household: true).where.not(id: excluded_person_id).exists?
  end

  # Whether a group with transaction history would change household status.
  # @return [Boolean]
  def household_change_affects_transaction?(owner, household_after)
    return false unless owner&.accounts_with_transactions&.exists?

    owner.household? != household_after
  end

  # Prevents a changed membership from reclassifying either group involved.
  # @return [void]
  def preserve_transaction_classification_on_update
    return unless person_id_changed? || group_id_changed?

    errors.add(:base, :cannot_change_with_transactions) if leaving_changes_household? || joining_changes_household?
  end

  # Whether removing the original membership reclassifies the original group.
  # @return [Boolean]
  def leaving_changes_household?
    original = Group.find_by(id: group_id_was)
    household_change_affects_transaction?(original, household_after_leaving(original))
  end

  # Whether the original group is a household once this membership leaves it.
  # Within the same group, the new person takes the old person's place.
  # @return [Boolean]
  def household_after_leaving(original)
    remaining = household_without(original, person_id_was)
    return remaining if group_id_changed?

    remaining || person&.household? || false
  end

  # Prevents destroying a membership that would reclassify the group.
  # @return [void]
  def preserve_transaction_classification_on_destroy
    return unless household_change_affects_transaction?(group, household_without(group, person_id))

    errors.add(:base, :cannot_change_with_transactions)
    throw :abort if destroyed_by_association.nil?
  end
end
