require "test_helper"

class TodosIndexTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "todo shows only the uncategorized remainder for partially split transactions" do
    get todo_path

    assert_response :success

    formatted_amount = Regexp.escape(ApplicationController.helpers.number_to_currency(10))
    formatted_note = Regexp.escape(transactions(:debit_grocery).note)

    assert_match %r{#{formatted_note}.*?#{formatted_amount}}m, response.body
  end

  test "todo keeps showing a nil-category remainder split as uncategorized" do
    transaction = transactions(:uncategorized)
    transaction.transaction_splits.create!(amount: 10.00, category: categories(:supermarket))
    transaction.ensure_remainder_split

    get todo_path

    assert_response :success

    formatted_amount = Regexp.escape(ApplicationController.helpers.number_to_currency(15))
    formatted_note = Regexp.escape(transaction.note)

    assert_match %r{#{formatted_note}.*?#{formatted_amount}}m, response.body
  end
end
