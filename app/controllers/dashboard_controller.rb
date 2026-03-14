# Displays financial dashboard for the current account
#
# Shows debit and credit transactions grouped by category for a date range,
# with calculations for profit/loss over the selected period.
class DashboardController < ApplicationController
  # Displays the account dashboard with categorized transactions and totals
  #
  # Supports optional date range filtering via params[:filter] (last_month, year_to_date, etc.)
  #
  # @return [void]
  def index
    dashboard = Dashboard.new(account: Current.account, filter: params[:filter])

    @debit_transactions = dashboard.debit_transactions
    @debit_total = dashboard.debit_total
    @credit_transactions = dashboard.credit_transactions
    @credit_total = dashboard.credit_total
    @profit_or_loss = dashboard.profit_or_loss
  end
end
