require "test_helper"

class ChartsHelperTest < ActionView::TestCase
  class SvgDonutChart < ActionView::TestCase
    test "returns SVG with one path per non-zero slice" do
      svg = ApplicationController.helpers.svg_donut_chart(labels: [ "Food", "Transport", "Housing" ], data: [ 100, 200, 300 ])

      assert_equal 3, svg.scan("<path").size
    end

    test "skips zero-value slices" do
      svg = ApplicationController.helpers.svg_donut_chart(labels: [ "Food", "Empty", "Housing" ], data: [ 100, 0, 300 ])

      assert_equal 2, svg.scan("<path").size
    end

    test "renders a circle not a path for a single non-zero slice" do
      svg = ApplicationController.helpers.svg_donut_chart(labels: [ "Food" ], data: [ 100 ])

      assert_includes svg, "<circle"
      assert_not_includes svg, "<path"
    end
  end

  class SvgBarChart < ActionView::TestCase
    test "returns SVG with correct number of rect elements" do
      svg = ApplicationController.helpers.svg_bar_chart(labels: [ "Food", "Transport", "Housing" ], data: [ 100, 200, 300 ])

      assert_equal 3, svg.scan("<rect").size
    end

    test "returns empty paragraph when labels are empty" do
      result = ApplicationController.helpers.svg_bar_chart(labels: [], data: [])

      assert_equal "<p></p>", result
    end

    test "includes a polyline element when reference is supplied" do
      svg = ApplicationController.helpers.svg_bar_chart(
        labels: [ "Food", "Transport" ],
        data: [ 100, 200 ],
        reference: [ 80, 160 ]
      )

      assert_includes svg, "<polyline"
    end

    test "does not include a polyline element without reference" do
      svg = ApplicationController.helpers.svg_bar_chart(labels: [ "Food", "Transport" ], data: [ 100, 200 ])

      assert_not_includes svg, "<polyline"
    end
  end
end
