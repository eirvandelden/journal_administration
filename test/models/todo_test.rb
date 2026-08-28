require "test_helper"

class TodoTest < ActiveSupport::TestCase
  test "show_upload_form? returns true when no transactions exist" do
    Chattel.update_all(purchase_transaction_id: nil)
    TransactionLink.delete_all
    TransactionSplit.delete_all
    Transaction.delete_all
    todo = Todo.new

    assert_predicate todo, :show_upload_form?
  end

  test "show_upload_form? returns true when latest transaction is older than threshold" do
    Transaction.update_all(booked_at: 14.days.ago)
    todo = Todo.new

    assert_predicate todo, :show_upload_form?
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

  test "items includes partially split transactions with remaining uncategorized balance" do
    todo = Todo.new

    transaction_records = todo.items.select { |item| item.kind == :transaction }.map(&:record)

    assert_includes transaction_records, transactions(:debit_grocery)
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

  test "empty? returns true when there is nothing left to do" do
    TransactionSplit.delete_all
    Transaction.where(category_id: nil).delete_all
    Account.update_all(updated_at: Time.current)
    Product.unclassified.update_all(brand: "AH", product_type_id: product_types(:naturel_chips).id)
    todo = Todo.new

    assert_empty todo
  end

  test "empty? returns false when uncategorized transactions exist" do
    todo = Todo.new

    assert_not todo.empty?
  end
  test "a product still needing a brand or type is something to do" do
    todo = Todo.new

    product_records = todo.items.select { |item| item.kind == :product }.map(&:record)

    assert_includes product_records, products(:andrelon_shampoo)
  end

  test "a product we have already classified is nothing to do" do
    todo = Todo.new

    product_records = todo.items.select { |item| item.kind == :product }.map(&:record)

    assert_not_includes product_records, products(:ah_ribbelchips)
  end
end
