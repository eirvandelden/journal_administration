require "test_helper"

class ProductsHelperTest < ActionView::TestCase
  test "two purchases are drawn from the left edge to the right" do
    points = price_chart_points([ BigDecimal("2.00"), BigDecimal("1.00") ], BigDecimal("2.00"))

    assert_equal "0.0,0.0 600.0,100.0", points
  end

  test "the dearest purchase sits at the top and half of it halfway down" do
    points = price_chart_points([ BigDecimal("4.00"), BigDecimal("2.00"), BigDecimal("4.00") ], BigDecimal("4.00"))

    assert_equal "0.0,0.0 300.0,100.0 600.0,0.0", points
  end

  test "a single purchase is not a line" do
    assert_equal "", price_chart_points([ BigDecimal("2.00") ], BigDecimal("2.00"))
  end

  test "prices that are all nothing draw nothing" do
    assert_equal "", price_chart_points([ BigDecimal("0"), BigDecimal("0") ], BigDecimal("0"))
  end
end
