# A sum the household sets aside for one purpose and recipient in one budget year
#
# Payments and split parts are charged to it; what is left never carries over to another year.
class Appropriation < ApplicationRecord
  belongs_to :person, optional: true

  has_many :transactions, dependent: :restrict_with_error
  has_many :transaction_splits, dependent: :restrict_with_error

  validates :purpose, presence: true
  validates :recipient, presence: true
  validates :budget_year, presence: true, numericality: { only_integer: true }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :managed_person_required
  validate :one_per_purpose_person_and_year
  validate :legacy_recipient_is_unchanged
  before_validation :assign_person_from_legacy_recipient, on: :create
  before_validation :set_legacy_recipient, on: :create

  scope :of_year, ->(year) { where(budget_year: year) }

  # Finds an appropriation by purpose, year, and the recipient's managed person.
  # @param purpose [String]
  # @param recipient [String]
  # @param budget_year [Integer]
  # @return [ActiveRecord::Relation]
  def self.named(purpose:, recipient:, budget_year:)
    person = person_named(recipient)
    return none unless person

    of_year(budget_year).where("LOWER(purpose) = LOWER(?)", purpose).where(person:)
  end

  # Names to suggest: household members and people with appropriations.
  # @return [Array<String>]
  def self.recipient_suggestions
    Person.where(household: true).or(Person.where(id: select(:person_id))).pluck(:name).sort_by(&:downcase)
  end

  # The people marked as household members.
  #
  # @return [Array<String>]
  def self.household_members
    Person.where(household: true).order(:name).pluck(:name)
  end

  # Finds one person by name without regard to letter case.
  # @param name [String]
  # @return [Person, nil]
  def self.person_named(name)
    Person.find_by(name_key: name.downcase) || Person.all.find { |entry| entry.name.casecmp?(name) }
  end

  # The name a person recognises it by, e.g. "Birthday Etienne 2026"
  #
  # @return [String]
  def to_s
    "#{purpose} #{recipient_name} #{budget_year}"
  end

  # The current managed recipient name.
  # @return [String]
  def recipient_name
    person&.name || recipient
  end

  # Charged payments and split parts, minus charged refunds
  #
  # @return [BigDecimal]
  def charged = @charged ||= charged_on("Debit") - charged_on("Credit")

  # What is left of the amount appropriated; negative when overspent
  #
  # @return [BigDecimal]
  def balance = amount - charged

  # Whether more was charged than appropriated
  #
  # @return [Boolean]
  def overspent? = balance.negative?

  # The payments and split parts charged to it, earliest payment first and undated ones last
  #
  # @return [Array<Transaction, TransactionSplit>]
  def charges
    dated, undated = (transactions.unscope(:order).to_a +
      transaction_splits.includes(:financial_transaction).to_a).partition(&:booked_at)

    dated.sort_by(&:booked_at) + undated
  end

  private

  # Requires a managed recipient for new appropriations.
  # @return [void]
  def managed_person_required
    errors.add(:recipient, :blank) if person.nil? && errors[:recipient].empty?
  end

  # Refuses a second appropriation for the same purpose, person and year.
  # @return [void]
  def one_per_purpose_person_and_year
    return unless namesake.exists?

    errors.add(:purpose, :already_appropriated)
  end

  # Other appropriations with this purpose, person and year.
  # @return [ActiveRecord::Relation]
  def namesake
    self.class.of_year(budget_year).where("LOWER(purpose) = LOWER(?)", purpose)
      .where(person_id:).where.not(id:)
  end

  # Keeps the legacy recipient text unchanged after creation.
  # @return [void]
  def legacy_recipient_is_unchanged
    errors.add(:recipient, :readonly) if persisted? && will_save_change_to_recipient?
  end

  # Finds an existing person or builds one from a legacy recipient submission.
  # @return [void]
  def assign_person_from_legacy_recipient
    return if person

    name = recipient
    return if name.blank?

    self.person = self.class.person_named(name)
  end

  # Copies the selected person's name into the immutable legacy column at creation.
  # @return [void]
  def set_legacy_recipient
    self.recipient = person.name if person.present?
  end

  # What is charged from payments of one type, whole or in parts
  def charged_on(type)
    transactions.unscope(:order).where(type:).sum(:amount) +
      transaction_splits.joins(:financial_transaction).where(transactions: { type: }).sum(:amount)
  end
end
