require "test_helper"

class TransactionAmountsTest < ActionDispatch::IntegrationTest
  setup do
    @transaction = transactions(:debit_bakery)
    sign_in_as(users(:admin))
  end

  test "a transaction of 150 cents shows as 1,50" do
    @transaction.update_columns(amount: 150)

    get transaction_url(@transaction)

    assert_response :success
    assert_select "dd", text: /1,50/
  end

  test "typing 1,50 stores 150 cents and the form shows 1,50 again" do
    patch transaction_url(@transaction), params: { transaction: { amount: "1,50" } }

    assert_response :redirect
    assert_equal 150, @transaction.reload.amount

    get edit_transaction_url(@transaction)

    assert_select "input[name$='[amount]'][value='1,50']"
  end

  test "typing 1,5 or 1.50 stores 150 cents" do
    [ "1,5", "1.50", "1,50" ].each do |typed|
      @transaction.update_columns(amount: 999)

      patch transaction_url(@transaction), params: { transaction: { amount: typed } }

      assert_equal 150, @transaction.reload.amount, "typed #{typed}"
    end
  end

  test "text that is not an amount is refused and shown again as typed" do
    patch transaction_url(@transaction), params: { transaction: { amount: "abc" } }

    assert_response :success
    assert_equal 1250, @transaction.reload.amount
    assert_select "input[name$='[amount]'][value='abc']"
  end

  test "a numeric JSON amount in euros stores cents" do
    patch transaction_url(@transaction), params: { transaction: { amount: 12.5 } },
      as: :json, headers: { "Accept" => "text/html" }

    assert_response :redirect
    assert_equal 1250, @transaction.reload.amount
  end

  test "a JSON amount with a fraction of a cent answers 422" do
    patch transaction_url(@transaction, format: :json),
      params: { transaction: { amount: 12.345 } }, as: :json

    assert_response :unprocessable_entity
    assert_predicate response.parsed_body["amount"], :present?
  end
end
