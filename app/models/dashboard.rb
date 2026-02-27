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

  # Returns debit transactions (money entering the account) grouped by category with totals
  #
  # @return [Hash{Category => Float}] Categories mapped to debit amounts
  def debit_transactions
    @debit_transactions ||= grouped_transactions_for(:debit)
  end

  # Returns credit transactions (money leaving the account) grouped by category with totals
  #
  # @return [Hash{Category => Float}] Categories mapped to credit amounts
  def credit_transactions
    @credit_transactions ||= grouped_transactions_for(:credit)
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

  def transfer_category_id
    @transfer_category_id ||= Category.find_by(name: "Transfer")&.id
  end

  def grouped_transactions_for(direction)
    transactions = grouped_amounts_for(direction)
    categories = indexed_categories_for(transactions.keys.compact)
    Category.sort_by_hierarchy(transactions.transform_keys { |category_id| categories[category_id] })
  end

  def grouped_amounts_for(direction)
    scope = transaction_scope_for(direction)
    scope.where.not(category_id: transfer_category_id)
         .or(scope.where(category_id: nil))
         .group(:category_id)
         .sum("ABS(mutations.amount)")
  end

  def transaction_scope_for(direction)
    mutation_scope = scoped_mutations_for(direction)
    Transaction.joins(:mutations)
               .where(mutations: { id: mutation_scope.select(:id) })
               .where(booked_at: date_range.to_range)
  end

  def scoped_mutations_for(direction)
    scope = Mutation.where(account_id: account.id)
    amount = Mutation.arel_table[:amount]
    condition = (direction == :debit) ? amount.gt(0) : amount.lt(0)
    scope.where(condition)
  end

  def indexed_categories_for(category_ids)
    Category.where(id: category_ids).includes(:parent_category).index_by(&:id)
  end
end
