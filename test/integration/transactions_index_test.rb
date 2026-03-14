require "test_helper"

class TransactionsIndexTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "index highlights uncategorized transactions" do
    get transactions_path

    assert_response :success
    assert_select "tr.unconsolidated", text: /Uncategorized tra/
  end

  test "index does not highlight categorized transactions" do
    get transactions_path

    assert_response :success
    assert_select "tr.unconsolidated", text: /Groceries at AH/, count: 0
  end

  test "GET /transactions returns 200" do
    get transactions_path

    assert_response :success
  end

  test "filter form is present on the index page" do
    get transactions_path

    assert_select "form[action='#{transactions_path}'][method='get']"
  end

  test "GET /transactions?type=Debit shows only debit rows" do
    get transactions_path, params: { type: "Debit" }

    assert_response :success
    assert_select "td", text: transactions(:debit_grocery).note
    assert_select "td", text: transactions(:credit_salary).note, count: 0
  end

  test "GET /transactions?category_id=none shows only uncategorized rows" do
    get transactions_path, params: { category_id: "none" }

    assert_response :success
    assert_select "tr.unconsolidated"
    assert_select "td", text: transactions(:debit_grocery).note, count: 0
  end

  test "GET /transactions?account_id= shows only transactions for that account" do
    account = accounts(:employer)
    get transactions_path, params: { account_id: account.id }

    assert_response :success
    assert_select "td", text: transactions(:credit_salary).note
    assert_select "td", text: transactions(:debit_grocery).note, count: 0
  end

  test "GET /transactions with date range shows date-filtered rows" do
    start_date = 2.days.ago.to_date.to_s
    end_date = Date.today.to_s

    get transactions_path, params: { start_date: start_date, end_date: end_date }

    assert_response :success
    assert_select "tr.unconsolidated"
    assert_select "td", text: transactions(:debit_grocery).note, count: 0
  end

  test "GET /transactions with invalid date params ignores invalid filters" do
    get transactions_path, params: { start_date: "not-a-date" }

    assert_response :success
    assert_select "td", text: transactions(:debit_grocery).note
    assert_select "td", text: transactions(:credit_salary).note
  end

  test "no_category filter includes partially split transactions with remaining balance" do
    get transactions_path(filter: :no_category)

    assert_response :success
    assert_includes response.body, transactions(:debit_grocery).note
  end

  class SplitSubRows < ActionDispatch::IntegrationTest
    setup do
      sign_in_as(users(:member))
    end

    test "split transaction shows sub-rows for each split" do
      get transactions_path

      assert_response :success
      assert_select "tr.split-row", minimum: 2
    end

    test "non-split transaction does not show sub-rows" do
      get transactions_path

      assert_response :success
      assert_select "tr" do |rows|
        bakery_row = rows.detect { |r| r.text.include?(transactions(:debit_bakery).note) }
        assert bakery_row
      end
    end
  end
end
