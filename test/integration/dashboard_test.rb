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

  test "dashboard with current_month filter shows transactions grouped by parent category" do
    get dashboard_index_url, params: { filter: "current_month" }

    assert_response :success
    assert_select "td", text: categories(:groceries).name
    assert_select "td", text: categories(:income).name
  end

  test "dashboard with current_year filter shows parent category totals" do
    get dashboard_index_url, params: { filter: "current_year" }

    assert_response :success
    assert_select "td", text: categories(:groceries).name
    assert_select "td", text: categories(:income).name
  end

  test "dashboard does not show child categories as separate rows" do
    get dashboard_index_url, params: { filter: "current_year" }

    assert_response :success
    assert_select "td", text: categories(:supermarket).full_name, count: 0
    assert_select "td", text: categories(:salary).full_name, count: 0
  end

  test "dashboard excludes transfer transactions" do
    get dashboard_index_url, params: { filter: "current_year" }

    assert_response :success
    assert_select "td", text: categories(:transfer).name, count: 0
  end

  test "dashboard with from_month and to_month filters transactions" do
    get dashboard_index_url, params: { from_month: "2026-01", to_month: "2026-12" }

    assert_response :success
    assert_select "table.debit_credit"
  end

  test "dashboard shows the month filter form" do
    get dashboard_index_url

    assert_response :success
    assert_select "form[data-controller='submit-on-change']"
    assert_select "select[name='from_month']"
    assert_select "select[name='to_month']"
  end

  test "the filter form offers months and never a day" do
    get dashboard_index_url

    assert_select "input[type='date']", count: 0
    assert_select "label", text: I18n.t("dashboard.filters.start_date", locale: users(:member).locale), count: 0
    assert_select "label", text: I18n.t("dashboard.filters.end_date", locale: users(:member).locale), count: 0
    assert_select "select[name='from_month'] option, select[name='to_month'] option" do |options|
      assert(options.all? { |option| option["value"].match?(/\A\d{4}-\d{2}\z/) })
    end
    assert_current_month_selected
  end

  test "the filter form labels its fields with months" do
    get dashboard_index_url

    assert_select "label[for='from_month']", text: I18n.t("dashboard.filters.from_month", locale: users(:member).locale)
    assert_select "label[for='to_month']", text: I18n.t("dashboard.filters.to_month", locale: users(:member).locale)
  end

  test "the quick filter is a select that submits the form on change" do
    get dashboard_index_url

    assert_select "select[name='filter'][data-action='change->submit-on-change#submit']"
  end

  test "a to month before the from month shows the current month" do
    get dashboard_index_url, params: { from_month: "2026-10", to_month: "2026-03" }

    assert_response :success
    assert_current_month_selected
  end

  test "old links with days show the current month" do
    get dashboard_index_url, params: { start_date: "2026-10-15", end_date: "2026-10-20" }

    assert_response :success
    assert_current_month_selected
  end

  class BudgetGoals < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(users(:member))
      BudgetCategory.delete_all
      Budget.delete_all
      budget = Budget.create!(starts_at: Time.zone.local(2024, 1, 1))
      BudgetCategory.create!(budget:, category: categories(:housing), amount: 1480)
    end

    test "October 2026 shows the stored monthly amount as the budget goal" do
      travel_to Time.zone.local(2026, 10, 22) do
        assert_goal_of 1, from_month: "2026-10", to_month: "2026-10"
      end
    end

    test "February 2026 shows the same budget goal as October 2026" do
      travel_to Time.zone.local(2026, 10, 22) do
        assert_goal_of 1, from_month: "2026-02", to_month: "2026-02"
      end
    end

    test "January to March 2026 shows three times the monthly budget goal" do
      travel_to Time.zone.local(2026, 10, 22) do
        assert_goal_of 3, from_month: "2026-01", to_month: "2026-03"
      end
    end

    test "this year in October shows ten months of budget and January through October" do
      travel_to Time.zone.local(2026, 10, 22) do
        assert_goal_of 10, filter: "current_year"
        assert_select "select[name='from_month'] option[selected][value='2026-01']"
        assert_select "select[name='to_month'] option[selected][value='2026-10']"
      end
    end

    test "last year shows twelve months of budget" do
      travel_to Time.zone.local(2026, 10, 22) do
        assert_goal_of 12, filter: "last_year"
      end
    end

    private

    def assert_goal_of(months, **params)
      get dashboard_index_url, params: params

      assert_response :success
      assert_select "td.amount",
text: ActionController::Base.helpers.number_to_currency(1480 * months, locale: users(:member).locale)
    end
  end

  test "dashboard shows budget columns when active budget exists" do
    get dashboard_index_url, params: { filter: "current_month" }

    assert_response :success
    assert_select "th", text: I18n.t("balance.budget")
    assert_select "th", text: I18n.t("balance.target")
    assert_select "th", text: I18n.t("balance.status")
  end

  test "dashboard shows budget chart heading when active budget exists" do
    get dashboard_index_url, params: { filter: "current_month" }

    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.charts.budget_vs_actual")
  end

  test "dashboard shows spending vs average chart when no active budget in date range" do
    Budget.destroy_all

    get dashboard_index_url, params: { filter: "current_month" }

    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.charts.spending_vs_average")
  end

  test "dashboard does not show budget columns when no active budget" do
    Budget.destroy_all

    get dashboard_index_url, params: { filter: "current_month" }

    assert_response :success
    assert_select "th", text: I18n.t("balance.budget"), count: 0
    assert_select "th", text: I18n.t("balance.status"), count: 0
  end

  test "dashboard shows spending_vs_average for a past range even when a current budget exists" do
    # active_budget fixture covers 2026-03-01 onwards; selecting 2025 has no matching budget
    get dashboard_index_url, params: { from_month: "2025-01", to_month: "2025-12" }

    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.charts.spending_vs_average")
  end

  test "dashboard hides budget columns for a past range even when a current budget exists" do
    get dashboard_index_url, params: { from_month: "2025-01", to_month: "2025-12" }

    assert_response :success
    assert_select "th", text: I18n.t("balance.budget"), count: 0
    assert_select "th", text: I18n.t("balance.status"), count: 0
  end

  test "dashboard hides budget columns when the selected range is broader than the budget period" do
    get dashboard_index_url, params: { from_month: "2026-01", to_month: "2026-12" }

    assert_response :success
    assert_select "h2", text: I18n.t("dashboard.charts.spending_vs_average")
    assert_select "th", text: I18n.t("balance.budget"), count: 0
    assert_select "th", text: I18n.t("balance.status"), count: 0
  end

  private

  def assert_current_month_selected
    assert_select "select[name='from_month'] option[selected][value='#{Date.current.strftime("%Y-%m")}']"
    assert_select "select[name='to_month'] option[selected][value='#{Date.current.strftime("%Y-%m")}']"
  end
end
