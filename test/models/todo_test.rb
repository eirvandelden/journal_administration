require "test_helper"

class TodoTest < ActiveSupport::TestCase
  test "show_upload_form? returns true when no transactions exist" do
    Chattel.update_all(purchase_transaction_id: nil)
    Transaction.destroy_all
    todo = Todo.new

    assert todo.show_upload_form?
  end

  test "show_upload_form? returns true when latest transaction is older than threshold" do
    Transaction.update_all(booked_at: 14.days.ago)
    todo = Todo.new

    assert todo.show_upload_form?
  end

  test "show_upload_form? returns false when latest transaction is recent" do
    Transaction.update_all(booked_at: 1.day.ago)
    todo = Todo.new

    assert_not todo.show_upload_form?
  end

  test "items includes uncategorized transactions" do
    todo = Todo.new

    kinds = todo.items.map(&:kind)
    assert_includes kinds, :transaction
  end

  test "items includes untouched accounts" do
    Account.where(name: "Unknown Account").update_all("updated_at = created_at")
    todo = Todo.new

    kinds = todo.items.map(&:kind)
    assert_includes kinds, :account
  end

  test "items are sorted newest-first" do
    todo = Todo.new

    dates = todo.items.map { |item| item.date.to_i }
    assert_equal dates.sort.reverse, dates
  end

  test "empty? returns true when no uncategorized transactions or untouched accounts" do
    Transaction.where(category_id: nil).destroy_all
    Account.update_all(updated_at: Time.current)
    todo = Todo.new

    assert todo.empty?
  end

  test "empty? returns false when uncategorized transactions exist" do
    todo = Todo.new

    assert_not todo.empty?
  end
end
