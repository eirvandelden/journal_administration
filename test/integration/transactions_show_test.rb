require "test_helper"

class TransactionsShowTest < ActionDispatch::IntegrationTest
  setup do
    @transaction = transactions(:debit_grocery)
    @uncategorized = transactions(:uncategorized)
    @admin = users(:admin)
    @member = users(:member)
  end

  test "show renders uncategorized category with translated label" do
    sign_in_as(@member)

    get transaction_url(@uncategorized)

    assert_response :success
    assert_select "dt", text: I18n.t("transactions.table.category")
    assert_select "dd", text: I18n.t("common.uncategorized")
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

  test "show displays unconsolidated notification for categorized transaction with uncategorized remainder" do
    sign_in_as(@member)
    get transaction_url(@transaction)

    assert_response :success
    assert_select "mark.unconsolidated"
  end

  test "show does not display unconsolidated notification for fully categorized transaction" do
    sign_in_as(@member)
    get transaction_url(transactions(:debit_bakery))

    assert_response :success
    assert_select "mark.unconsolidated", count: 0
  end

  test "show does not display unconsolidated notification for fully split transaction" do
    @uncategorized.transaction_splits.create!(amount: @uncategorized.amount, category: categories(:supermarket))

    sign_in_as(@member)

    get transaction_url(@uncategorized)

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

  test "show page has new chattel link pre-filled with transaction id" do
    sign_in_as(@member)

    get transaction_url(@transaction)

    assert_response :success
    assert_select "a[href=?]", new_chattel_path(purchase_transaction_id: @transaction.id)
  end

  test "show page displays proof-of-purchase section" do
    sign_in_as(@member)

    get transaction_url(@transaction)

    assert_response :success
    assert_select "h2", text: I18n.t("transactions.show.proof_of_purchase")
    assert_select "p", text: I18n.t("transactions.show.no_proof_of_purchase")
  end

  test "show counts and renders only explicit splits" do
    @uncategorized.transaction_splits.create!(category: categories(:supermarket), amount: 1000, note: "Food")
    @uncategorized.ensure_remainder_split

    sign_in_as(@member)

    get transaction_url(@uncategorized)

    assert_response :success
    assert_select "dt", text: I18n.t("transaction_splits.split_indicator", count: 1)
    assert_select "dd ul li", count: 1
    assert_select "dd ul li", text: /Supermarket/
    assert_select "dd ul li", text: /10\.00/
  end

  test "the edit page of a credit links back to the credit's own page" do
    sign_in_as(@member)
    credit = transactions(:credit_salary)

    get edit_transaction_path(credit)

    assert_select "a[href='#{credit_path(credit)}']"
  end

  test "Nieuw bezit sits in the Acties menu beside Bewerken" do
    sign_in_as(@member)

    get transaction_url(@transaction)

    assert_select "main > header nav > details > summary", text: I18n.t("common.actions_menu")
    assert_select "main > header nav > details a[href=?]", new_chattel_path(purchase_transaction_id: @transaction.id)
    assert_select "main > header nav > a[href=?]", edit_transaction_path(@transaction)
    assert_select "main > header nav > details a[href=?]", edit_transaction_path(@transaction), count: 0
  end

  test "show page has no delete button" do
    sign_in_as(@member)

    get transaction_url(@transaction)

    assert_select "button.button-danger", count: 0
  end

  test "the edit page ends the transaction form in an action row with Verwijderen…" do
    sign_in_as(@member)

    get edit_transaction_path(@transaction)

    assert_select "form[action=?] > footer button.button-danger[form=?]",
      polymorphic_path(@transaction), dom_id(@transaction, :delete)
    assert_select "form##{dom_id(@transaction, :delete)}[action=?]", transaction_path(@transaction)
    assert_select "main > .actions", count: 0
  end
end
