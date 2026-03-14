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
end
