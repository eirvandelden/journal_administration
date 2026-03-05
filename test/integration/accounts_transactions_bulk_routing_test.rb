require "test_helper"

class AccountsTransactionsBulkRoutingTest < ActionDispatch::IntegrationTest
  test "PATCH /accounts/:id/transactions_bulk routes to Accounts::TransactionsBulkController" do
    assert_routing(
      { method: "patch", path: "/accounts/1/transactions_bulk" },
      { controller: "accounts/transactions_bulk", action: "update", account_id: "1" }
    )
  end
end
