require "test_helper"

class TodoTest < ActiveSupport::TestCase
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
    Transaction.where(category_id: nil).delete_all
    Account.update_all(updated_at: Time.current)
    todo = Todo.new

    assert todo.empty?
  end

  test "empty? returns false when uncategorized transactions exist" do
    todo = Todo.new

    assert_not todo.empty?
  end
end
