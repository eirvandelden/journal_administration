require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "a product with a brand and a product type is classified" do
    assert_not products(:ah_ribbelchips).unclassified?
  end

  test "a product straight off an invoice still needs its brand and type" do
    assert products(:andrelon_shampoo).unclassified?
  end

  test "a product without a brand is unclassified" do
    products(:ah_ribbelchips).brand = ""

    assert products(:ah_ribbelchips).unclassified?
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
    older.lines.create!(product: products(:lays_ribbelchips), quantity: 1, pack_amount: 300, pack_unit: :gram,
                        full_amount: 2.29, discount_amount: 0, paid_amount: 2.29)

    purchases = products(:lays_ribbelchips).purchases

    assert_equal [ receipts(:albert_heijn_friday), older ], purchases.map(&:receipt)
  end

  test "a product we never bought has no purchases" do
    assert_empty products(:andrelon_shampoo).purchases
  end
end
