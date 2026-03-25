require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  test "initializes with default filter" do
    dashboard = Dashboard.new

    assert_instance_of DateRange, dashboard.date_range
  end

  test "initializes with explicit filter" do
    dashboard = Dashboard.new(filter: "last_year")

    assert_equal Time.current.last_year.beginning_of_year.to_date, dashboard.date_range.start_date.to_date
  end

  test "debit_transactions returns a hash" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_instance_of Hash, dashboard.debit_transactions
  end

  test "credit_transactions returns a hash" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_instance_of Hash, dashboard.credit_transactions
  end

  test "debit_total sums debit transaction values" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_equal dashboard.debit_transactions.values.sum, dashboard.debit_total
  end

  test "credit_sub_total sums credit transaction values" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_equal dashboard.credit_transactions.values.sum, dashboard.credit_sub_total
  end

  test "profit_or_loss equals debit_total minus credit_sub_total" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_equal dashboard.debit_total - dashboard.credit_sub_total, dashboard.profit_or_loss
  end

  test "credit_total equals credit_sub_total plus profit_or_loss" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_equal dashboard.credit_sub_total + dashboard.profit_or_loss, dashboard.credit_total
  end

  test "debit_transactions groups by parent category" do
    dashboard = Dashboard.new(filter: "year_to_date")

    keys = dashboard.debit_transactions.keys.compact
    assert keys.all? { |category| category.parent_category.nil? },
           "Expected all debit transaction keys to be parent (root) categories"
  end

  test "credit_transactions groups by parent category" do
    dashboard = Dashboard.new(filter: "year_to_date")

    keys = dashboard.credit_transactions.keys.compact
    assert keys.all? { |category| category.parent_category.nil? },
           "Expected all credit transaction keys to be parent (root) categories"
  end

  test "debit_transactions aggregates multiple child category amounts into parent" do
    dashboard = Dashboard.new(filter: "year_to_date")

    expected_total = 52.50
    assert_equal expected_total, dashboard.debit_transactions[categories(:groceries)]
  end

  test "credit_transactions aggregates child category amounts into parent" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_equal transactions(:credit_salary).amount, dashboard.credit_transactions[categories(:income)]
  end

  test "excludes transfer transactions" do
    dashboard = Dashboard.new(filter: "year_to_date")

    transfer_category = categories(:transfer)
    assert_nil dashboard.debit_transactions[transfer_category]
    assert_nil dashboard.credit_transactions[transfer_category]
  end

  test "includes uncategorized transactions" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert dashboard.debit_transactions.key?(nil),
           "Expected uncategorized debit transactions to appear with nil key"
  end

  test "debit_transactions use split amounts for split transactions" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_equal 52.50, dashboard.debit_transactions[categories(:groceries)]
  end

  test "debit_transactions keep remaining split balance uncategorized" do
    dashboard = Dashboard.new(filter: "year_to_date")

    assert_equal 35.00, dashboard.debit_transactions[nil]
  end

  test "month_to_date filter uses beginning of month to now" do
    dashboard = Dashboard.new(filter: "month_to_date")

    assert_equal Time.current.beginning_of_month.to_date, dashboard.date_range.start_date.to_date
    assert_in_delta Time.current, dashboard.date_range.end_date, 5.seconds
  end

  test "initializes with custom start_date and end_date" do
    dashboard = Dashboard.new(start_date: "2026-03-01", end_date: "2026-03-31")

    assert_equal Date.parse("2026-03-01"), dashboard.date_range.start_date.to_date
    assert_equal Date.parse("2026-03-31"), dashboard.date_range.end_date.to_date
  end

  test "custom start_date and end_date override filter" do
    dashboard = Dashboard.new(filter: "last_year", start_date: "2026-03-01", end_date: "2026-03-31")

    assert_equal Date.parse("2026-03-01"), dashboard.date_range.start_date.to_date
    assert_equal Date.parse("2026-03-31"), dashboard.date_range.end_date.to_date
  end

  class ChartLabels < ActiveSupport::TestCase
    test "returns an array of strings in the same order as credit_transactions" do
      dashboard = Dashboard.new(filter: "year_to_date")
      labels = dashboard.chart_labels
      keys = dashboard.credit_transactions.keys

      assert_equal keys.size, labels.size
      assert labels.all? { |l| l.is_a?(String) }
    end

    test "maps nil category key to translated uncategorized label" do
      dashboard = Dashboard.new(filter: "year_to_date")

      nil_index = dashboard.credit_transactions.keys.index(nil)
      assert_equal I18n.t("common.uncategorized"), dashboard.chart_labels[nil_index] if nil_index
    end
  end

  class HistoricalAverages < ActiveSupport::TestCase
    test "returns array of same length as chart_labels" do
      dashboard = Dashboard.new(filter: "year_to_date")

      assert_equal dashboard.chart_labels.size, dashboard.historical_averages.size
    end

    test "returns zeros when no prior-year data exists" do
      # Fixtures are booked in current month; year_to_date lookback covers the previous year
      dashboard = Dashboard.new(filter: "year_to_date")

      assert dashboard.historical_averages.all? { |v| v == 0.0 },
             "Expected all historical averages to be zero when no prior-year transactions exist"
    end
  end

  class ActiveBudget < ActiveSupport::TestCase
    setup do
      BudgetCategory.delete_all
      Budget.delete_all
    end

    test "returns nil when no active budget exists" do
      dashboard = Dashboard.new(filter: "year_to_date")

      assert_nil dashboard.active_budget
    end

    test "returns nil when date range is outside all budgets" do
      Budget.create!(starts_at: 1.month.ago, ends_at: 1.week.ago)

      dashboard = Dashboard.new(start_date: "2024-01-01", end_date: "2024-01-31")
      assert_nil dashboard.active_budget
    end

    test "returns budget overlapping the selected date range" do
      past_budget = Budget.create!(starts_at: 3.months.ago, ends_at: 2.months.ago)

      dashboard = Dashboard.new(
        start_date: 3.months.ago.to_date.to_s,
        end_date: 2.months.ago.to_date.to_s
      )
      assert_equal past_budget, dashboard.active_budget
    end

    test "returns period-specific budget, not the currently active one, for a past range" do
      Budget.create!(starts_at: 1.month.ago, ends_at: 1.week.ago)
      past_budget = Budget.create!(starts_at: 3.months.ago, ends_at: 2.months.ago)

      dashboard = Dashboard.new(
        start_date: 3.months.ago.to_date.to_s,
        end_date: 2.months.ago.to_date.to_s
      )
      assert_equal past_budget, dashboard.active_budget
    end
  end

  class BudgetAmounts < ActiveSupport::TestCase
    setup do
      BudgetCategory.delete_all
      Budget.delete_all
    end

    test "returns empty hash when no active budget" do
      dashboard = Dashboard.new(filter: "year_to_date")

      assert_equal({}, dashboard.budget_amounts)
    end
  end
end
