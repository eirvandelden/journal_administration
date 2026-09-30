# A sum the household sets aside for one purpose and recipient in one budget year
#
# Payments and split parts are charged to it; what is left never carries over to another year.
class Appropriation < ApplicationRecord
  has_many :transactions, dependent: :restrict_with_error
  has_many :transaction_splits, dependent: :restrict_with_error

  validates :purpose, presence: true
  validates :recipient, presence: true
  validates :budget_year, presence: true, numericality: { only_integer: true }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validate :one_per_purpose_recipient_and_year

  scope :of_year, ->(year) { where(budget_year: year) }
  scope :named, ->(purpose:, recipient:, budget_year:) {
    of_year(budget_year).where("LOWER(purpose) = LOWER(?) AND LOWER(recipient) = LOWER(?)", purpose, recipient)
  }

  # The name a person recognises it by, e.g. "Birthday Etienne 2026"
  #
  # @return [String]
  def to_s = "#{purpose} #{recipient} #{budget_year}"

  # Charged payments and split parts, minus charged refunds
  #
  # @return [BigDecimal]
  def charged = @charged ||= charged_on("Debit") - charged_on("Credit")

  # Reloads the record and forgets what was worked out as charged
  #
  # @return [Appropriation]
  def reload(*)
    @charged = nil
    super
  end

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

  # Refuses a second appropriation for the same purpose, recipient and year, ignoring letter case
  def one_per_purpose_recipient_and_year
    return unless namesake.exists?

    errors.add(:purpose, :already_appropriated)
  end

  # Other appropriations with this purpose, recipient and year
  def namesake = Appropriation.named(purpose:, recipient:, budget_year:).where.not(id:)

  # What is charged from payments of one type, whole or in parts
  def charged_on(type)
    transactions.unscope(:order).where(type:).sum(:amount) +
      transaction_splits.joins(:financial_transaction).where(transactions: { type: }).sum(:amount)
  end
end
