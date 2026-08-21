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
end
