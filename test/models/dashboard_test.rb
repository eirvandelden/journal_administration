require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  test "initializes with account and default filter" do
    dashboard = Dashboard.new(account: accounts(:checking))

    assert_equal accounts(:checking), dashboard.account
    assert_instance_of DateRange, dashboard.date_range
  end

  test "initializes with explicit filter" do
    dashboard = Dashboard.new(account: accounts(:checking), filter: "last_year")

    assert_equal Time.current.last_year.beginning_of_year.to_date, dashboard.date_range.start_date.to_date
  end

  test "debit_transactions returns a hash" do
    dashboard = Dashboard.new(account: accounts(:checking), filter: "year_to_date")

    assert_instance_of Hash, dashboard.debit_transactions
  end

  test "credit_transactions returns a hash" do
    dashboard = Dashboard.new(account: accounts(:checking), filter: "year_to_date")

    assert_instance_of Hash, dashboard.credit_transactions
  end

  test "debit_total sums debit transaction values" do
    dashboard = Dashboard.new(account: accounts(:checking), filter: "year_to_date")

    assert_equal dashboard.debit_transactions.values.sum, dashboard.debit_total
  end

  test "credit_sub_total sums credit transaction values" do
    dashboard = Dashboard.new(account: accounts(:checking), filter: "year_to_date")

    assert_equal dashboard.credit_transactions.values.sum, dashboard.credit_sub_total
  end

  test "profit_or_loss equals debit_total minus credit_sub_total" do
    dashboard = Dashboard.new(account: accounts(:checking), filter: "year_to_date")

    assert_equal dashboard.debit_total - dashboard.credit_sub_total, dashboard.profit_or_loss
  end

  test "credit_total equals credit_sub_total plus profit_or_loss" do
    dashboard = Dashboard.new(account: accounts(:checking), filter: "year_to_date")

    assert_equal dashboard.credit_sub_total + dashboard.profit_or_loss, dashboard.credit_total
  end
end
