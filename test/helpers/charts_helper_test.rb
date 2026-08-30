require "test_helper"

class ChartsHelperTest < ActionView::TestCase
  class SvgDonutChart < ActionView::TestCase
    test "returns SVG with one path per non-zero slice" do
      svg = ApplicationController.helpers.svg_donut_chart(labels: [ "Food", "Transport", "Housing" ],
data: [ 100, 200, 300 ])

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
      svg = ApplicationController.helpers.svg_bar_chart(labels: [ "Food", "Transport", "Housing" ],
data: [ 100, 200, 300 ])

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

  class SvgBudgetChart < ActionView::TestCase
    test "returns empty paragraph when there is nothing to show" do
      result = svg_budget_chart(budget_amounts: {}, budget_actuals: {})

      assert_equal content_tag(:p, ""), result
    end

    test "renders an SVG element when a budget line has an actual amount" do
      result = svg_budget_chart(
        budget_amounts: { categories(:groceries) => 200 },
        budget_actuals: { categories(:groceries) => 150 }
      )

      assert_match(/<svg/, result)
    end

    test "renders green bar when debit category is under 80% of budget" do
      result = svg_budget_chart(
        budget_amounts: { categories(:groceries) => 1000 },
        budget_actuals: { categories(:groceries) => 700 }
      )

      assert_match(/green/, result)
    end

    test "renders red bar when debit category exceeds budget" do
      result = svg_budget_chart(
        budget_amounts: { categories(:groceries) => 100 },
        budget_actuals: { categories(:groceries) => 200 }
      )

      assert_match(/red/, result)
    end

    test "renders red bar when credit category is below 50% of target" do
      result = svg_budget_chart(
        budget_amounts: { categories(:income) => 100 },
        budget_actuals: { categories(:income) => -40 }
      )

      assert_match(/red/, result)
    end

    test "renders grey bar for categories without a budget line" do
      result = svg_budget_chart(
        budget_amounts: { categories(:groceries) => 200 },
        budget_actuals: { categories(:housing) => 500 }
      )

      assert_match(/grey|gray|#888|muted/, result)
    end
  end
end
