require "test_helper"

class TodosIndexTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "todo shows only the uncategorized remainder for partially split transactions" do
    get todo_path

    assert_response :success

    formatted_amount = Regexp.escape(ApplicationController.helpers.cents_to_currency(1000))
    formatted_note = Regexp.escape(transactions(:debit_grocery).note)

    assert_match %r{#{formatted_note}.*?#{formatted_amount}}m, response.body
  end

  test "todo keeps showing a nil-category remainder split as uncategorized" do
    transaction = transactions(:uncategorized)
    transaction.transaction_splits.create!(amount: 1000, category: categories(:supermarket))
    transaction.ensure_remainder_split

    get todo_path

    assert_response :success

    formatted_amount = Regexp.escape(ApplicationController.helpers.cents_to_currency(1500))
    formatted_note = Regexp.escape(transaction.note)

    assert_match %r{#{formatted_note}.*?#{formatted_amount}}m, response.body
  end

  test "the todo page links a product still needing a type to its page" do
    get todo_path

    assert_response :success
    assert_select "a[href=?]", product_path(products(:andrelon_shampoo))
  end

  test "rows open the record's show page and carry no action column" do
    get todo_path

    assert_select "main > header > h1", count: 1
    assert_select "tbody td a[href=?]", product_path(products(:andrelon_shampoo))
    assert_select "tbody button", count: 0
    assert_select "table[data-stack] tbody td:not([data-label])", count: 0
  end
end
