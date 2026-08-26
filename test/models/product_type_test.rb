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
  test "a product type knows the products we buy under it" do
    products_bought = product_types(:naturel_chips).latest_purchase_per_product.keys

    assert_includes products_bought, products(:ah_ribbelchips)
    assert_includes products_bought, products(:lays_ribbelchips)
  end

  test "a product type knows what each product last cost per unit" do
    latest = product_types(:naturel_chips).latest_purchase_per_product

    assert_equal BigDecimal("4.97"), latest[products(:ah_ribbelchips)].paid_price_per_unit
    assert_equal BigDecimal("4.97"), latest[products(:lays_ribbelchips)].paid_price_per_unit
  end

  test "a product type totals what we spent per month, and how much of it was on bonus" do
    month = receipts(:albert_heijn_friday).issued_on.beginning_of_month
    totals = product_types(:naturel_chips).monthly_totals[month]

    assert_equal BigDecimal("2.98"), totals.spent
    assert_equal 2, totals.count
    assert_equal 1, totals.on_bonus_count
  end

  test "a product type nothing was bought under totals nothing" do
    shampoo = ProductType.create!(name: "Shampoo", category: categories(:household))

    assert_empty shampoo.monthly_totals
  end
end
