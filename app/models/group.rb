# Represents a named collection of people that can own an account.
class Group < ApplicationRecord
  has_many :group_memberships, dependent: :destroy
  has_many :people, through: :group_memberships
  has_many :accounts, dependent: :restrict_with_error

  validates :name, presence: true
  validate :name_key_is_unique
  validate :preserve_transaction_classification
  before_validation :normalize_name_key
  after_save :apply_selected_people

  # The selected member ids submitted with this group.
  # @return [Array<Integer>]
  def person_ids
    @selected_person_ids || people.ids
  end

  # Defers member replacement until group validation succeeds.
  # @param ids [Array<String, Integer>]
  # @return [void]
  def person_ids=(ids)
    @selected_person_ids = Array(ids).reject(&:blank?).map(&:to_i).uniq
  end

  # Whether at least one member belongs to the household.
  # @return [Boolean]
  def household?
    return people.any?(&:household?) if people.loaded?

    people.where(household: true).exists?
  end

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

  # Refuses member changes that alter account classification with history.
  # @return [void]
  def preserve_transaction_classification
    return unless @selected_person_ids

    unless selected_people.count == @selected_person_ids.count
      errors.add(:person_ids, :invalid)
      return
    end

    return unless accounts_with_transactions.exists?

    return if household? == selected_people.where(household: true).exists?

    errors.add(:base, :cannot_change_with_transactions)
  end

  # The people chosen for this update.
  # @return [ActiveRecord::Relation<Person>]
  def selected_people
    Person.where(id: @selected_person_ids)
  end

  # Stores the Unicode-aware key used by the unique database index.
  # @return [void]
  def normalize_name_key
    self.name_key = name.downcase if name.present?
  end

  # Applies member changes after all group validations pass.
  # @return [void]
  def apply_selected_people
    return unless @selected_person_ids

    (@selected_person_ids - group_memberships.pluck(:person_id)).each do |id|
      group_memberships.create!(person_id: id)
    end
    group_memberships.where.not(person_id: @selected_person_ids).find_each(&:destroy!)
    @selected_person_ids = nil
  end
end
