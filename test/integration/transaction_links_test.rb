require "test_helper"

class TransactionLinksTest < ActionDispatch::IntegrationTest
  setup do
    @member = users(:member)
    @debit = transactions(:debit_grocery)
    @transfer = transactions(:transfer_for_grocery)
    sign_in_as(@member)
  end

  # -- create -----------------------------------------------------------------

  test "create links a transfer to a source transaction" do
    @debit.transaction_links.destroy_all

    assert_difference "TransactionLink.count", 1 do
      post transaction_transaction_links_url(@debit),
        params: { transfer_id: @transfer.id }
    end

    assert_response :redirect
    assert_redirected_to edit_transaction_url(@debit)
  end

  test "create via turbo stream re-renders linking section" do
    @debit.transaction_links.destroy_all

    post transaction_transaction_links_url(@debit),
      params: { transfer_id: @transfer.id },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
  end

  # -- destroy ----------------------------------------------------------------

  test "destroy removes a transaction link" do
    link = transaction_links(:grocery_to_transfer)

    assert_difference "TransactionLink.count", -1 do
      delete transaction_transaction_link_url(@debit, link)
    end

    assert_response :redirect
    assert_redirected_to edit_transaction_url(@debit)
  end

  test "destroy via turbo stream re-renders linking section" do
    link = transaction_links(:grocery_to_transfer)

    delete transaction_transaction_link_url(@debit, link),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
  end

  # -- edit page rendering ----------------------------------------------------

  test "edit page shows linking section for Debit transactions" do
    get edit_transaction_url(@debit)

    assert_response :success
    assert_select "turbo-frame#transaction_links"
  end

  test "edit page hides linking section for Transfer transactions" do
    get edit_transaction_url(transactions(:transfer_savings))

    assert_response :success
    assert_select "turbo-frame#transaction_links", count: 0
  end
end
