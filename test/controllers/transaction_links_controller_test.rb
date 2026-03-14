require "test_helper"

class TransactionLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:admin)
    @transaction = transactions(:debit_grocery)
  end

  class Index < TransactionLinksControllerTest
    test "returns no results without a query" do
      get transaction_transaction_links_path(@transaction)

      assert_response :success
      assert_select "table", count: 0
    end

    test "returns matching unlinked transfers for a query" do
      get transaction_transaction_links_path(@transaction), params: { query: "savings" }

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "td", text: /Transfer to savings/
    end

    test "excludes transfers already linked to this transaction" do
      get transaction_transaction_links_path(@transaction), params: { query: "groceries" }

      assert_response :success
      assert_select "tbody tr", count: 0
    end

    test "excludes transfers linked to other source transactions" do
      get transaction_transaction_links_path(transactions(:debit_bakery)), params: { query: "groceries" }

      assert_response :success
      assert_select "tbody tr", count: 0
    end

    test "filters by amount" do
      get transaction_transaction_links_path(@transaction), params: { amount: "500.00" }

      assert_response :success
      assert_select "tbody tr", count: 1
      assert_select "td", text: /Transfer to savings/
    end

    test "shows no results message when search yields nothing" do
      get transaction_transaction_links_path(@transaction), params: { query: "nonexistent" }

      assert_response :success
      assert_select "table", count: 0
    end
  end
end
