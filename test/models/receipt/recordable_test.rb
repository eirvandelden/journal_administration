require "test_helper"

class Receipt::RecordableTest < ActiveSupport::TestCase
  Basket = Struct.new(:order_number, :delivered_on, :total_amount, :lines, :packed?)
  Line = Importing::AlbertHeijn::PackingSlip::Line

  test "record_basket creates a delivery for a new order number" do
    receipt = assert_difference "Receipt.count", 1 do
      Receipt.record_basket(basket(lines: [ Line.new("AH Chips naturel", 2, 258, 58) ]))
    end

    assert_equal "900", receipt.order_number
    assert_equal [ 200 ], receipt.lines.map(&:paid_amount)
  end

  test "books the delivery to the Albert Heijn B.V. account" do
    assert_equal accounts(:albert_heijn), Receipt.record_basket(basket).shop
  end

  test "replaces the lines of a changed basket" do
    Receipt.record_basket(basket)

    receipt = Receipt.record_basket(basket(lines: [ Line.new("AH Komkommer", 1, 79, 0) ]))

    assert_equal [ "AH Komkommer" ], receipt.lines.map { |line| line.product.name }
  end

  test "lets a packing slip replace a confirmation" do
    Receipt.record_basket(basket(packed: false))

    receipt = Receipt.record_basket(basket(packed: true, lines: [ Line.new("AH Komkommer", 1, 79, 0) ]))

    assert_predicate receipt, :packed?
    assert_equal [ "AH Komkommer" ], receipt.lines.map { |line| line.product.name }
  end

  test "splits a linked payment again when the basket changes" do
    Product.create!(name: "AH Chips naturel", brand: "AH", product_type: product_types(:naturel_chips))
    receipt = Receipt.record_basket(basket)
    receipt.update!(payment: transactions(:debit_grocery))

    Receipt.record_basket(basket(lines: [ Line.new("AH Chips naturel", 3, 387, 0) ]))

    assert_equal [ 387 ], receipt.payment.explicit_transaction_splits.map(&:amount)
  end

  test "an unchanged basket is read in four queries and writes nothing" do
    Receipt.record_basket(basket)

    queries = capture_queries { Receipt.record_basket(basket) }

    assert_operator queries.size, :<=, 4
    assert_empty queries.grep(/\A\s*(INSERT|UPDATE|DELETE)/i)
  end

  test "a confirmation after a packing slip keeps the packed lines" do
    Receipt.record_basket(basket(packed: true))

    receipt = Receipt.record_basket(basket(packed: false, lines: [ Line.new("AH Komkommer", 1, 79, 0) ]))

    assert_equal 1, receipt.lines.count
    assert_equal "AH Chips naturel", receipt.lines.first.product.name
  end

  private

  def basket(packed: true, lines: [ Line.new("AH Chips naturel", 1, 129, 0) ])
    Basket.new("900", Date.new(2026, 9, 1), 5000, lines, packed)
  end

  def capture_queries
    queries = []
    callback = ->(*, payload) {
 queries << payload[:sql] unless payload[:name] == "SCHEMA" || payload[:sql].match?(/SAVEPOINT/) }
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    queries
  end
end
