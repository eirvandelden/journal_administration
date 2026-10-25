require "test_helper"
require_relative "../test_helpers/assistant_requests"

# A tool that prints a record's category or charge must not query once per row it prints
class AssistantQueryCountsTest < ActionDispatch::IntegrationTest
  include AssistantRequests

  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
  end

  test "listing product types runs as many queries for many child categories as for one" do
    ProductType.create!(name: "Rolls", category: categories(:supermarket))
    ask_assistant("list_product_types")
    one = queries_for { ask_assistant("list_product_types") }
    ProductType.create!(name: "Cakes", category: categories(:bakery))
    ProductType.create!(name: "Pipes", category: categories(:rent))

    assert_equal one, queries_for { ask_assistant("list_product_types") }
  end

  test "finding transactions runs as many queries for many child categories as for one" do
    one = queries_for { ask_assistant("find_transactions", type: "Debit") }
    many = queries_for { ask_assistant("find_transactions") }

    assert_equal one, many
  end

  test "showing a receipt runs as many queries for many child categories as for one" do
    receipt = receipt_with_lines(categories(:supermarket))
    ask_assistant("show_receipt", receipt_id: receipt.id)
    one = queries_for { ask_assistant("show_receipt", receipt_id: receipt.id) }
    add_line(receipt, "Cake", categories(:bakery))
    add_line(receipt, "Pipe", categories(:rent))

    assert_equal one, queries_for { ask_assistant("show_receipt", receipt_id: receipt.id) }
  end

  test "showing a payment runs as many queries for many charged parts as for one" do
    payment = transactions(:debit_grocery)
    transaction_splits(:split_grocery_bakery).update!(appropriation: appropriations(:birthday_etienne))
    ask_assistant("show_transaction", transaction_id: payment.id)
    one = queries_for { ask_assistant("show_transaction", transaction_id: payment.id) }
    transaction_splits(:split_grocery_supermarket).update!(appropriation: appropriations(:christmas_etienne))
    payment.transaction_splits.create!(category: categories(:rent), amount: 500,
      appropriation: appropriations(:sinterklaas_chiara))

    assert_equal one, queries_for { ask_assistant("show_transaction", transaction_id: payment.id) }
  end

  private

  def receipt_with_lines(category)
    Receipt.create!(shop: accounts(:albert_heijn), issued_on: Date.current, total_amount: 100).tap do |receipt|
      add_line(receipt, "Roll", category)
    end
  end

  def add_line(receipt, name, category)
    type = ProductType.find_or_create_by!(name: "Type #{name}") { |new_type| new_type.category = category }
    product = Product.create!(name: name, brand: "AH", product_type: type)
    receipt.lines.create!(product:, quantity: 1, full_amount: 100, discount_amount: 0, paid_amount: 100)
  end
end
