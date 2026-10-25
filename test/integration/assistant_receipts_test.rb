require "test_helper"
require_relative "../test_helpers/assistant_requests"

class AssistantReceiptsTest < ActionDispatch::IntegrationTest
  include AssistantRequests

  setup do
    host! "localhost"
    @user = users(:admin)
    @user.regenerate_assistant_token
  end

  test "the assistant files a pasted receipt with its lines" do
    answer = file_pasted_receipt

    receipt = Receipt.order(:id).last

    assert_equal accounts(:albert_heijn), receipt.shop
    assert_equal Date.new(2026, 9, 5), receipt.issued_on
    assert_equal 1234, receipt.total_amount
    assert_equal [ "Brood", "Melk" ], receipt.lines.map { |line| line.product.name }.sort
    assert_includes answer, "Filed receipt ##{receipt.id}"
    assert_includes answer, "12.34"
    assert_includes answer, "Brood"
  end

  test "a product nobody has seen before is listed as unclassified" do
    file_pasted_receipt

    answer = ask_assistant("list_products", unclassified: true)

    assert_includes answer, "Brood"
    assert_includes answer, "(unclassified)"
  end

  test "filing the same receipt twice is refused and names the first one" do
    file_pasted_receipt
    first = Receipt.order(:id).last

    assert refused?("file_receipt", pasted_receipt)
    assert_equal first, Receipt.order(:id).last
    assert_includes ask_assistant("file_receipt", pasted_receipt), "##{first.id}"
  end

  test "linking a receipt splits its payment the way the basket divides" do
    receipt = receipts(:albert_heijn_friday)
    payment = transactions(:debit_grocery)

    answer = ask_assistant("link_receipt_payment", receipt_id: receipt.id, transaction_id: payment.id)

    assert_equal receipt, payment.reload.receipt
    assert_equal({ categories(:groceries) => 298, categories(:household) => 349 },
      payment.explicit_transaction_splits.to_h { |split| [ split.category, split.amount ] })
    assert_equal payment.amount, payment.transaction_splits.sum(:amount)
    payment.transaction_splits.each { |split| assert_includes answer, "#{split.id}: " }
  end

  test "a pasted receipt ends as a split payment with a part charged to an appropriation" do
    file_pasted_receipt(issued_on: transactions(:debit_grocery).booked_at.to_date.to_s)
    receipt = Receipt.order(:id).last
    receipt.lines.each { |line| classify(line.product, categories(:groceries)) }

    ask_assistant("link_receipt_payment", receipt_id: receipt.id, transaction_id: transactions(:debit_grocery).id)
    part = transactions(:debit_grocery).reload.explicit_transaction_splits.first
    answer = ask_assistant("charge_to_appropriation", appropriation_id: appropriations(:birthday_etienne).id,
      transaction_id: transactions(:debit_grocery).id, transaction_split_id: part.id)

    assert_equal appropriations(:birthday_etienne), part.reload.appropriation
    assert_includes answer, "Charged"
  end

  test "filing a receipt without a valid token is turned away" do
    post_to_assistant(method: "tools/call", params: { name: "file_receipt", arguments: pasted_receipt }, token: nil)

    assert_response :unauthorized
    assert_no_difference "Receipt.count" do
      post_to_assistant(method: "tools/call", params: { name: "file_receipt", arguments: pasted_receipt },
        token: "not-a-real-token")
    end
  end

  test "listing receipts runs as many queries for three receipts as for one" do
    Receipt.create!(shop: accounts(:jumbo), issued_on: Date.current, total_amount: 100)
    ask_assistant("list_receipts", limit: 1)
    one = queries_for { ask_assistant("list_receipts", limit: 1) }
    many = queries_for { ask_assistant("list_receipts", limit: 100) }

    assert_equal one, many
  end

  private

  def file_pasted_receipt(**changes) = ask_assistant("file_receipt", pasted_receipt.merge(changes))

  def pasted_receipt
    { shop_id: accounts(:albert_heijn).id, issued_on: "2026-09-05", total_amount: 12.34,
      lines: [ { name: "Brood", quantity: 1, full_amount: 2.5 },
               { name: "Melk", quantity: 2, full_amount: 2.19, discount_amount: 0.7 } ] }
  end

  def classify(product, category)
    type = ProductType.find_or_create_by!(name: "Test #{category.name}") { |new_type| new_type.category = category }
    product.update!(brand: "AH", product_type: type)
  end

  def queries_for(&)
    count = 0
    counter = ->(*, payload) { count += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end
end
