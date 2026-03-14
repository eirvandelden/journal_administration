# Displays financial dashboard for all family accounts
#
# Shows debit and credit transactions grouped by category for a date range,
# with calculations for profit/loss over the selected period.
class DashboardController < ApplicationController
  # Displays the dashboard with categorized transactions and totals
  #
  # Supports date range filtering via params[:start_date] and params[:end_date],
  # or optional filter (last_month, year_to_date, etc.)
  #
  # @action GET
  # @route /dashboard
  #
  # @return [void]
  def index
    @dashboard = Dashboard.new(start_date: params[:start_date], end_date: params[:end_date], filter: params[:filter])
  end
end
