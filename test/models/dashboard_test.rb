require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  class InitializationTest < DashboardTest
    test "initializes with account and default filter" do
      dashboard = Dashboard.new(account: accounts(:checking))

      assert_equal accounts(:checking), dashboard.account
      assert_instance_of DateRange, dashboard.date_range
    end

    test "initializes with explicit filter" do
      dashboard = Dashboard.new(account: accounts(:checking), filter: "last_year")

      assert_equal Time.current.last_year.beginning_of_year.to_date, dashboard.date_range.start_date.to_date
    end
  end

  class GroupingTest < DashboardTest
    test "debit_transactions groups debit values by category and keeps uncategorized totals" do
      dashboard = year_to_date_dashboard

      assert_equal 3000, dashboard.debit_transactions[categories(:salary)]
      assert_equal 75, dashboard.debit_transactions[nil]
    end

    test "credit_transactions groups credit values by category" do
      dashboard = year_to_date_dashboard

      assert_equal 50, dashboard.credit_transactions[categories(:supermarket)]
      assert_equal 25, dashboard.credit_transactions[nil]
    end
  end

  class TotalsTest < DashboardTest
    test "debit_total returns the summed incoming amount for the account" do
      assert_equal 3075, year_to_date_dashboard.debit_total
    end

    test "credit_sub_total returns the summed outgoing amount excluding transfers" do
      assert_equal 75, year_to_date_dashboard.credit_sub_total
    end

    test "profit_or_loss returns debit total minus credit subtotal" do
      assert_equal 3000, year_to_date_dashboard.profit_or_loss
    end

    test "credit_total balances credit side to match debit total" do
      assert_equal 3075, year_to_date_dashboard.credit_total
    end
  end

  private

  def year_to_date_dashboard
    Dashboard.new(account: accounts(:checking), filter: "year_to_date")
  end
end
