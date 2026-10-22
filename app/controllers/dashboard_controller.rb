# Displays the household finance dashboard.
#
# Shows debit and credit transactions grouped by category for a date range,
# with calculations for profit/loss over the selected period.
class DashboardController < ApplicationController
  # Displays the dashboard with categorized transactions and totals
  #
  # Supports period filtering via params[:from_month] and params[:to_month] (YYYY-MM),
  # or a quick filter (current_month, last_month, three_months, current_year, last_year)
  #
  # @action GET
  # @route /dashboard
  #
  # @return [void]
  def index
    @dashboard = Dashboard.new(date_range: MonthRange.from_selection(
      filter: params[:filter], from_month: params[:from_month], to_month: params[:to_month]
    ))
  end
end
