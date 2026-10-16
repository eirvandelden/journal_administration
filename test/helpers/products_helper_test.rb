require "test_helper"

class ProductsHelperTest < ActionView::TestCase
  test "two purchases are drawn from the left edge to the right" do
    points = price_chart_points([ 200, 100 ], 200)

    assert_equal "0.0,0.0 600.0,100.0", points
  end

  test "the dearest purchase sits at the top and half of it halfway down" do
    points = price_chart_points([ 400, 200, 400 ], 400)

    assert_equal "0.0,0.0 300.0,100.0 600.0,0.0", points
  end

  test "a single purchase is not a line" do
    assert_equal "", price_chart_points([ 200 ], 200)
  end

  test "plots Integer cents without truncating" do
    points = price_chart_points([ 100, 300 ], 300)

    assert_equal "0.0,133.3 600.0,0.0", points
  end

  test "prices that are all nothing draw nothing" do
    assert_equal "", price_chart_points([ 0, 0 ], 0)
  end
end
