require "test_helper"
require_relative "../test_helpers/assistant_requests"

class AssistantTransactionsTest < ActionDispatch::IntegrationTest
  include AssistantRequests

  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
  end

  test "the assistant deletes a transaction" do
    transaction = transactions(:uncategorized)

    answer = ask_assistant("delete_transaction", transaction_id: transaction.id)

    assert_not Transaction.exists?(transaction.id)
    assert_includes answer, "Deleted transaction ##{transaction.id}"
  end

  test "deleting a transaction a chattel was bought with is refused" do
    transaction = transactions(:debit_grocery)

    assert refused?("delete_transaction", transaction_id: transaction.id)
    assert_includes ask_assistant("delete_transaction", transaction_id: transaction.id), "Laptop"
    assert Transaction.exists?(transaction.id)
  end

  test "the assistant books, finds, shows and changes a transaction" do
    ask_assistant("create_transaction", debitor_account_id: accounts(:checking).id,
      creditor_account_id: accounts(:jumbo).id, amount: 9.99, booked_on: "2026-09-01", note: "Jumbo run")
    transaction = Transaction.find_by!(note: "Jumbo run")

    assert_equal "Debit", transaction.type
    assert_includes ask_assistant("find_transactions", query: "Jumbo run"), "#{transaction.id}: Debit"
    assert_includes ask_assistant("show_transaction", transaction_id: transaction.id), "9.99"

    ask_assistant("update_transaction", transaction_id: transaction.id, amount: 8.50,
      category_id: categories(:groceries).id)

    assert_equal 850, transaction.reload.amount
    assert_equal categories(:groceries), transaction.category
  end
end
