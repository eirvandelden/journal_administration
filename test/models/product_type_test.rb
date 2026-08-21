require "test_helper"

class ProductTypeTest < ActiveSupport::TestCase
  test "a product type is booked to an accounting category" do
    assert_equal categories(:groceries), product_types(:naturel_chips).category
  end

  test "a product type needs a name" do
    product_type = ProductType.new(category: categories(:groceries))

    assert_not product_type.valid?
    assert_includes product_type.errors[:name], "can't be blank"
  end
end
