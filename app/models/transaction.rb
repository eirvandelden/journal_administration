# Represents a financial transaction between accounts
#
# Transactions are single-table inheritance with three types: Credit, Debit, Transfer.
# The type is automatically determined by which accounts are family-owned accounts.
class Transaction < ApplicationRecord
  include Accountable
  include Categorizable
  include Importable
  include Linkable
  include Searchable
  include PdfAttachmentValidatable
  include Splittable

  searchable_on :note, :original_note

  # Overrides the default Searchable scope to also match by amount
  #
  # @param query [String] The search query
  # @return [ActiveRecord::Relation]
  scope :search, ->(query) {
    return none if query.blank?

    sanitized = "%#{sanitize_sql_like(query.to_s.strip)}%"
    t = arel_table
    text_conditions = searchable_columns.map { |col| t[col].matches(sanitized) }
    where(text_conditions.reduce(:or)).or(
      where("CAST(amount AS TEXT) LIKE ?", sanitized)
    ).limit(10)
  }

  TYPES = %w[Credit Debit Transfer].freeze

  default_scope { order(booked_at: :desc) }

  scope :by_type,       ->(type) { where(type: type) if type.present? }
  scope :by_category,   ->(id) { id == "none" ? where(category: nil) : where(category_id: id) if id.present? }
  scope :by_account,    ->(id) { where(debitor_account_id: id).or(where(creditor_account_id: id)) if id.present? }
  scope :in_date_range, ->(from, to) {
    rel = all
    from_date = klass.send(:parse_filter_date, from)
    to_date = klass.send(:parse_filter_date, to)

    rel = rel.where("interest_at >= ?", from_date.beginning_of_day) if from_date
    rel = rel.where("interest_at <= ?", to_date.end_of_day) if to_date
    rel
  }

  belongs_to :debitor, class_name: "Account", foreign_key: "debitor_account_id", optional: true
  belongs_to :creditor, class_name: "Account", foreign_key: "creditor_account_id", optional: true
  belongs_to :category, optional: true
  has_many :chattels, foreign_key: :purchase_transaction_id
  has_one_attached :proof_of_purchase

  scope :uncategorized, -> { where(Transaction.send(:uncategorized_clause)) }

  before_validation :determine_debit_credit_or_transfer_type

  validates :type, inclusion: { in: TYPES, message: "%{value} is not a valid type" }, presence: true
  validates_pdf_attachment_of :proof_of_purchase
  validate :check_transfer_type_through_account_owners

  # Returns true when the transaction has no category assigned.
  #
  # @return [Boolean]
  def consolidatable?
    category.nil?
  end

  # Returns an emoji representation of the transaction type
  #
  # @return [String] emoji icon (e.g., "⬇️ 🟥" for Credit)
  def type_icon
    case self.type
    when "Credit"
      "⬇️ 🟥"
    when "Debit"
      "⬆️ 🟩"
    when "Transfer"
      "🔄 ◻️"
    end
  end

  private

  def self.parse_filter_date(value)
    return if value.blank?

    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end
  private_class_method :parse_filter_date

  def self.uncategorized_clause
    <<~SQL.squish
      (
        transactions.category_id IS NULL
        AND NOT EXISTS (
          SELECT 1
          FROM transaction_splits
          WHERE transaction_splits.transaction_id = transactions.id
        )
      )
      OR EXISTS (
        SELECT 1
        FROM transaction_splits
        WHERE transaction_splits.transaction_id = transactions.id
          AND transaction_splits.category_id IS NULL
      )
      OR EXISTS (
        SELECT 1
        FROM transaction_splits
        WHERE transaction_splits.transaction_id = transactions.id
        GROUP BY transaction_splits.transaction_id
        HAVING transactions.amount > SUM(transaction_splits.amount)
      )
    SQL
  end
  private_class_method :uncategorized_clause

  # Determines transaction type based on account ownership
  #
  # Sets the type to Transfer if both accounts are family-owned,
  # Credit if creditor is family-owned, or Debit if debitor is family-owned.
  #
  # @return [void]
  def determine_debit_credit_or_transfer_type
    # is debitor_account owned by us? This is a Debit Transaction!
    # is creditor_account owned by us? This is a Credit Transaction!
    # are both owned by the same owner? This is a Transfer Transaction! (Or a Debit + Credit Transaction)
    return if type.present?
    return self.type = "Transfer" if debitor_is_us? && creditor_is_us?
    return self.type = "Credit" if creditor_is_us?
    self.type        = "Debit" if debitor_is_us?
  end

  def check_transfer_type_through_account_owners
    if type == "Transfer"
      unless debitor_is_us? && creditor_is_us?
        errors.add(:type, "must be Transfer only if both debitor and creditor are family accounts")
      end
    elsif type == "Debit"
      unless debitor_is_us?
        errors.add(:type, "must be Debit only if debitor is a family account")
      end
    elsif type == "Credit"
      unless creditor_is_us?
        errors.add(:type, "must be Credit only if creditor is a family account")
      end
    end
  end
end
