# Provides financial dashboard data over a date range
#
# Aggregates all family transactions by category, calculates totals, and determines
# profit/loss. Uses STI types (Debit/Credit) to identify family transactions without
# requiring a specific account.
class Dashboard
  # @return [DateRange] The date range for the dashboard
  attr_reader :date_range

  # Initializes a new dashboard
  #
  # @param filter [String, nil] Date range filter (e.g., "last_month", "year_to_date")
  # @param start_date [String, Date, nil] Custom start date (overrides filter)
  # @param end_date [String, Date, nil] Custom end date (overrides filter)
  def initialize(filter: nil, start_date: nil, end_date: nil)
    @date_range = custom_date_range(start_date, end_date) || DateRange.from_filter(filter)
  end

  # Returns debit transactions grouped by category with totals
  #
  # @return [Hash{Category => Float}] Categories mapped to debit amounts
  def debit_transactions
    @debit_transactions ||= grouped_transactions_for(Debit)
  end

  # Returns credit transactions grouped by category with totals
  #
  # @return [Hash{Category => Float}] Categories mapped to credit amounts
  def credit_transactions
    @credit_transactions ||= grouped_transactions_for(Credit)
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

  def custom_date_range(start_date, end_date)
    return unless start_date.present? && end_date.present?

    DateRange.from_dates(start_date, end_date)
  end

  def transfer_category_id
    @transfer_category_id ||= Category.find_by(name: "Transfer")&.id
  end

  def grouped_transactions_for(transaction_class)
    scope = transaction_class.where(booked_at: date_range.to_range)

    transactions = scope.where.not(category_id: transfer_category_id)
                       .or(scope.where(category_id: nil))
                       .group(:category_id)
                       .sum(:amount)

    category_ids = transactions.keys.compact
    categories = Category.where(id: category_ids).includes(:parent_category).index_by(&:id)

    transactions_by_category = transactions.transform_keys { |category_id| categories[category_id] }

    transactions_by_parent = transactions_by_category.each_with_object({}) do |(category, amount), result|
      parent = category&.parent_category || category
      result[parent] = (result[parent] || 0) + amount
    end

    Category.sort_by_hierarchy(transactions_by_parent)
  end
end
