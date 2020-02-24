require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    @transaction = transactions(:one)
  end

  test "visiting the index" do
    visit transactions_url
    assert_selector "h1", text: "Transactions"
  end

  test "creating a Transaction" do
    visit transactions_url
    click_on "New Transaction"

    fill_in "Amount", with: @transaction.amount
    fill_in "Booked at", with: @transaction.booked_at
    fill_in "Category", with: @transaction.category_id
    fill_in "From account", with: @transaction.from_account_id
    fill_in "Id", with: @transaction.id
    fill_in "Interest at", with: @transaction.interest_at
    fill_in "Note", with: @transaction.note
    fill_in "To account", with: @transaction.to_account_id
    fill_in "Type", with: @transaction.type
    click_on "Create Transaction"

    assert_text "Transaction was successfully created"
    click_on "Back"
  end

  test "updating a Transaction" do
    visit transactions_url
    click_on "Edit", match: :first

    fill_in "Amount", with: @transaction.amount
    fill_in "Booked at", with: @transaction.booked_at
    fill_in "Category", with: @transaction.category_id
    fill_in "From account", with: @transaction.from_account_id
    fill_in "Id", with: @transaction.id
    fill_in "Interest at", with: @transaction.interest_at
    fill_in "Note", with: @transaction.note
    fill_in "To account", with: @transaction.to_account_id
    fill_in "Type", with: @transaction.type
    click_on "Update Transaction"

    assert_text "Transaction was successfully updated"
    click_on "Back"
  end

  test "destroying a Transaction" do
    visit transactions_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Transaction was successfully destroyed"
  end
end
