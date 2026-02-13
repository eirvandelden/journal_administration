# Provides financial dashboard data for an account over a date range
#
# Dashboard aggregates transactions by category, calculates totals, and determines
# profit/loss. Uses efficient database queries to avoid N+1 problems.
class Dashboard
  # @return [Account] The account being analyzed
  attr_reader :account

  # @return [DateRange] The date range for the dashboard
  attr_reader :date_range

  # Initializes a new dashboard for an account
  #
  # @param account [Account] The account to analyze
  # @param filter [String, nil] Date range filter (e.g., "last_month", "year_to_date")
  def initialize(account:, filter: nil)
    @account = account
    @date_range = DateRange.from_filter(filter)
  end

  # Returns debit transactions grouped by category with totals
  #
  # @return [Hash{Category => Float}] Categories mapped to debit amounts
  def debit_transactions
    @debit_transactions ||= grouped_transactions_for(Debit, :debitor_account_id)
  end

  # Returns credit transactions grouped by category with totals
  #
  # @return [Hash{Category => Float}] Categories mapped to credit amounts
  def credit_transactions
    @credit_transactions ||= grouped_transactions_for(Credit, :creditor_account_id)
  end

  # Calculates total debit amount
  #
  # @return [Float] Sum of all debit transactions
  def debit_total
    debit_transactions.values.sum
  end

  # Calculates total credit amount (excluding transfers)
  #
  # @return [Float] Sum of all credit transactions
  def credit_sub_total
    credit_transactions.values.sum
  end

  # Calculates profit or loss (debit - credit)
  #
  # @return [Float] Profit if positive, loss if negative
  def profit_or_loss
    debit_total - credit_sub_total
  end

  # Calculates total credit including profit/loss adjustment
  #
  # @return [Float] Credit subtotal plus profit/loss
  def credit_total
    credit_sub_total + profit_or_loss
  end

  private

  def grouped_transactions_for(transaction_class, account_column)
    transfer_category_id = Category.find_by(name: "Transfer")&.id
    scope = transaction_class.where(account_column => account.id,
                                    booked_at: date_range.to_range)

    transactions = scope.where.not(category_id: transfer_category_id)
                       .or(scope.where(category_id: nil))
                       .group(:category_id)
                       .sum(:amount)

    category_ids = transactions.keys.compact
    categories = Category.where(id: category_ids).includes(:parent_category).index_by(&:id)

    transactions_by_category = transactions.transform_keys { |category_id| categories[category_id] }

    Category.sort_by_hierarchy(transactions_by_category)
  end
end
