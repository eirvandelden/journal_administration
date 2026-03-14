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
end
