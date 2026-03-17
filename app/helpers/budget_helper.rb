# Helpers for rendering budget status indicators.
module BudgetHelper
  # Returns the status symbol for a category row.
  #
  # For credit categories (spending limit):
  #   - :green when actual < 80% of budget
  #   - :orange when 80% <= actual <= 100% of budget
  #   - :red when actual > 100% of budget
  #
  # For debit categories (savings target):
  #   - :green when actual >= 100% of target
  #   - :orange when 50% <= actual < 100% of target
  #   - :red when actual < 50% of target
  #
  # @param category [Category] the category
  # @param actual [Numeric] actual amount
  # @param budgeted [Numeric, nil] budget amount
  # @return [Symbol, nil] :green, :orange, :red, or nil
  def budget_status(category:, actual:, budgeted:)
    return nil if budgeted.nil? || budgeted.to_f.zero?

    pct = actual.to_f / budgeted.to_f
    if category.credit?
      pct < 0.8 ? :green : pct <= 1.0 ? :orange : :red
    else
      pct >= 1.0 ? :green : pct >= 0.5 ? :orange : :red
    end
  end

  # Formats a percentage badge label, e.g. "73%".
  #
  # @param actual [Numeric] actual amount
  # @param budgeted [Numeric, nil] budget amount
  # @return [String] formatted percentage or empty string
  def budget_pct_label(actual:, budgeted:)
    return "" if budgeted.nil? || budgeted.to_f.zero?

    "#{(actual.to_f / budgeted.to_f * 100).round}%"
  end
end
