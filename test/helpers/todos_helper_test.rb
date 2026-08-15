require "test_helper"

class TodosHelperTest < ActionView::TestCase
  class TodoDescription < ActionView::TestCase
    test "transaction: joins the note and the uncategorized amount" do
      transaction = transactions(:debit_grocery)
      item = Todo::Item.new(:transaction, transaction.booked_at, transaction)

      formatted_amount = number_to_currency(transaction.uncategorized_amount)

      assert_equal "#{transaction.note} #{formatted_amount}", todo_description(item)
    end

    test "account: returns the account's name" do
      account = accounts(:checking)
      item = Todo::Item.new(:account, account.created_at, account)

      assert_equal account.name, todo_description(item)
    end
  end
end
