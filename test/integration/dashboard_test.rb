require "test_helper"

class MainDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:member)
    sign_in_as(@user)
  end

  test "dashboard is accessible" do
    get dashboard_index_url

    assert_response :success
  end

  test "dashboard shows debit and credit table" do
    get dashboard_index_url

    assert_select "table.debit_credit"
    assert_select "th"
  end

  test "dashboard shows the spending charts" do
    get dashboard_index_url

    assert_response :success
    assert_select "section.chart-section", count: 2
    assert_select "svg[role='img']", minimum: 1
  end

  test "dashboard with month_to_date filter shows transactions grouped by parent category" do
    get dashboard_index_url, params: { filter: "month_to_date" }

    assert_response :success
    assert_select "td", text: categories(:groceries).name
    assert_select "td", text: categories(:income).name
  end

  test "dashboard with year_to_date filter shows parent category totals" do
    get dashboard_index_url, params: { filter: "year_to_date" }

    assert_response :success
    assert_select "td", text: categories(:groceries).name
    assert_select "td", text: categories(:income).name
  end

  test "dashboard does not show child categories as separate rows" do
    get dashboard_index_url, params: { filter: "year_to_date" }

    assert_response :success
    assert_select "td", text: categories(:supermarket).full_name, count: 0
    assert_select "td", text: categories(:salary).full_name, count: 0
  end

  test "dashboard excludes transfer transactions" do
    get dashboard_index_url, params: { filter: "year_to_date" }

    assert_response :success
    assert_select "td", text: categories(:transfer).name, count: 0
  end

  test "dashboard with start_date and end_date filters transactions" do
    get dashboard_index_url, params: { start_date: "2026-01-01", end_date: "2026-12-31" }

    assert_response :success
    assert_select "table.debit_credit"
  end

  test "dashboard shows date filter form" do
    get dashboard_index_url

    assert_response :success
    assert_select "form[data-controller='date-filter']"
    assert_select "input[type='date'][name='start_date']"
    assert_select "input[type='date'][name='end_date']"
  end

  test "date filter form has quick filter select" do
    get dashboard_index_url

    assert_response :success
    assert_select "select[data-date-filter-target='quickFilter']"
  end

  test "dashboard with invalid custom dates falls back to the default range" do
    get dashboard_index_url, params: { start_date: "not-a-date", end_date: "2026-03-31" }

    assert_response :success
    assert_select "input[name='start_date'][value='#{Time.current.beginning_of_month.to_date.iso8601}']"
    assert_select "input[name='end_date'][value='#{Time.current.end_of_month.to_date.iso8601}']"
  end

  test "dashboard shows budget columns when active budget exists" do
    get dashboard_index_url, params: { filter: "month_to_date" }

    assert_response :success
    assert_select "th", text: I18n.t("balance.budget")
    assert_select "th", text: I18n.t("balance.target")
    assert_select "th", text: I18n.t("balance.status")
  end

  test "dashboard shows budget chart heading when active budget exists" do
    get dashboard_index_url, params: { filter: "month_to_date" }

    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.charts.budget_vs_actual")
  end

  test "dashboard shows spending vs average chart when no active budget in date range" do
    # Destroy the active budget fixture to simulate no active budget
    budgets(:active_budget).destroy

    get dashboard_index_url, params: { filter: "month_to_date" }

    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.charts.spending_vs_average")
  end

  test "dashboard does not show budget columns when no active budget" do
    budgets(:active_budget).destroy

    get dashboard_index_url, params: { filter: "month_to_date" }

    assert_response :success
    assert_select "th", text: I18n.t("balance.budget"), count: 0
    assert_select "th", text: I18n.t("balance.status"), count: 0
  end

  test "dashboard shows spending_vs_average for a past range even when a current budget exists" do
    # active_budget fixture covers 2026-03-01 onwards; selecting 2025 has no matching budget
    get dashboard_index_url, params: { start_date: "2025-01-01", end_date: "2025-12-31" }

    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.charts.spending_vs_average")
  end

  test "dashboard hides budget columns for a past range even when a current budget exists" do
    get dashboard_index_url, params: { start_date: "2025-01-01", end_date: "2025-12-31" }

    assert_response :success
    assert_select "th", text: I18n.t("balance.budget"), count: 0
    assert_select "th", text: I18n.t("balance.status"), count: 0
  end
end
