require "test_helper"

class Importing::AlbertHeijn::ImportJobTest < ActiveJob::TestCase
  setup do
    @slip = file_fixture("albert_heijn_packing_slip.txt").read
  end

  test "importing a packing slip records the basket that was delivered" do
    assert_difference "Receipt.count", 1 do
      Importing::AlbertHeijn::ImportJob.perform_now(@slip)
    end

    receipt = Receipt.find_by(order_number: "100000001")

    assert_equal accounts(:albert_heijn), receipt.shop
    assert_equal Date.new(2026, 8, 28), receipt.issued_on
    assert_equal BigDecimal("119.93"), receipt.total_amount
    assert_equal 37, receipt.lines.count
  end

  test "a bonus shows up on the line as what came off it" do
    Importing::AlbertHeijn::ImportJob.perform_now(@slip)

    line = ReceiptLine.joins(:product).find_by(products: { name: "Vivera Plantaardige kipstukjes" })

    assert_equal BigDecimal("13.96"), line.full_amount
    assert_equal BigDecimal("6.98"), line.discount_amount
    assert_equal BigDecimal("6.98"), line.paid_amount
  end

  test "a product we have never bought before is created for classifying" do
    Importing::AlbertHeijn::ImportJob.perform_now(@slip)

    assert_predicate Product.find_by(name: "Knorr Wereldgerechten Italiaanse risotto XL"), :unclassified?
  end

  test "a product we already know is reused rather than recorded twice" do
    known = Product.create!(name: "AH Broccoliroosjes", brand: "AH", product_type: product_types(:naturel_chips))

    Importing::AlbertHeijn::ImportJob.perform_now(@slip)

    assert_equal 1, Product.where("LOWER(name) = ?", "ah broccoliroosjes").count
    assert_equal known, ReceiptLine.joins(:product).find_by(products: { name: known.name }).product
  end

  test "importing the same slip again keeps one delivery with one basket" do
    Importing::AlbertHeijn::ImportJob.perform_now(@slip)

    assert_no_difference [ "Receipt.count", "ReceiptLine.count" ] do
      Importing::AlbertHeijn::ImportJob.perform_now(@slip)
    end
  end

  test "a delivery is left for a person to settle against a payment" do
    Importing::AlbertHeijn::ImportJob.perform_now(@slip)

    assert_nil Receipt.find_by(order_number: "100000001").payment
  end

  test "mail that is not a packing slip records nothing" do
    assert_no_difference "Receipt.count" do
      Importing::AlbertHeijn::ImportJob.perform_now("Beste familie, hier is een nieuwsbrief.")
    end
  end
end
