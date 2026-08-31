require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "a product with a brand and a product type is classified" do
    assert_not products(:ah_ribbelchips).unclassified?
  end

  test "a product straight off an invoice still needs its brand and type" do
    assert_predicate products(:andrelon_shampoo), :unclassified?
  end

  test "a product without a brand is unclassified" do
    products(:ah_ribbelchips).brand = ""

    assert_predicate products(:ah_ribbelchips), :unclassified?
  end

  test "a product needs a name" do
    product = Product.new

    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "products still needing classification can be listed" do
    assert_includes Product.unclassified, products(:andrelon_shampoo)
    assert_not_includes Product.unclassified, products(:ah_ribbelchips)
  end

  test "a product knows every time we bought it, newest first" do
    older = Receipt.create!(shop: accounts(:albert_heijn), issued_on: 2.months.ago.to_date, total_amount: 5.00)
    older.lines.create!(product: products(:lays_ribbelchips), quantity: 1, full_amount: 2.29,
                        discount_amount: 0, paid_amount: 2.29)

    purchases = products(:lays_ribbelchips).purchases

    assert_equal [ receipts(:albert_heijn_friday), older ], purchases.map(&:receipt)
  end

  test "a product we never bought has no purchases" do
    assert_empty products(:andrelon_shampoo).purchases
  end

  test "a product is found by its name however it was capitalised" do
    assert_equal products(:ah_ribbelchips), Product.resolve_by_name("ah naturel ribbelchips")
  end

  test "a name we have never bought starts a new unclassified product" do
    product = nil

    assert_difference "Product.count", 1 do
      product = Product.resolve_by_name("Knorr Maaltijdmix tagliatelle")
    end

    assert_predicate product, :unclassified?
  end

  test "two products cannot share a name" do
    duplicate = Product.new(name: products(:ah_ribbelchips).name.upcase)

    assert_not duplicate.valid?
  end

  test "a product whose brand is only whitespace still needs classifying" do
    product = products(:ah_ribbelchips)
    product.update!(brand: " ")

    assert_predicate product, :unclassified?
    assert_includes Product.unclassified, product
  end

  test "a product with an accent is found however the shop capitalised it" do
    known = Product.create!(name: "Karvan Cévitam Zero bosvruchten")

    assert_equal known, Product.resolve_by_name("KARVAN CÉVITAM ZERO BOSVRUCHTEN")
  end

  test "a product stored in capitals with an accent is not recorded twice" do
    shouting = Product.create!(name: "AH CAFÉ CREMA BONEN")

    assert_no_difference "Product.count" do
      assert_equal shouting, Product.resolve_by_name("AH Café Crema bonen")
    end
  end
end
