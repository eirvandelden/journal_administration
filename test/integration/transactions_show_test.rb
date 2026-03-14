require "test_helper"

class TransactionsShowTest < ActionDispatch::IntegrationTest
  setup do
    @transaction = transactions(:debit_grocery)
    @uncategorized = transactions(:uncategorized)
    @admin = users(:admin)
    @member = users(:member)
  end

  test "show renders uncategorized category as dash" do
    sign_in_as(@member)

    get transaction_url(@uncategorized)

    assert_response :success
    assert_select "dt", text: I18n.t("transactions.table.category")
    assert_select "dd", text: "-"
  end

  test "show renders original import fields for administrators" do
    @transaction.update!(
      original_note: "Imported original note",
      original_balance_after_mutation: "1200.50",
      original_tag: "ORIG-TAG"
    )

    sign_in_as(@admin)

    get transaction_url(@transaction)

    assert_response :success
    assert_select "dd", text: "Imported original note"
    assert_select "dd", text: /1200\.5/
    assert_select "dd", text: "ORIG-TAG"
  end

  test "show displays unconsolidated notification for uncategorized transaction" do
    sign_in_as(@member)
    get transaction_url(@uncategorized)
    assert_response :success
    assert_select "mark.unconsolidated"
  end

  test "show does not display unconsolidated notification for categorized transaction" do
    sign_in_as(@member)
    get transaction_url(@transaction)
    assert_response :success
    assert_select "mark.unconsolidated", count: 0
  end

  test "show hides original import fields for non-admin users" do
    @transaction.update!(
      original_note: "Imported original note",
      original_balance_after_mutation: "1200.50",
      original_tag: "ORIG-TAG"
    )

    sign_in_as(@member)

    get transaction_url(@transaction)

    assert_response :success
    assert_select "dd", text: "Imported original note", count: 0
    assert_select "dd", text: /1200\.5/, count: 0
    assert_select "dd", text: "ORIG-TAG", count: 0
  end
end
