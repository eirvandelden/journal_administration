require "test_helper"

class TransactionsIndexTest < ActionDispatch::IntegrationTest
  test "index does not render link to create a new transaction" do
    sign_in_as(users(:member))

    get transactions_path

    assert_response :success
    assert_select "a[href='#{new_transaction_path}']", count: 0
  end
end
