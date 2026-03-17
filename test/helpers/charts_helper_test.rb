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

  class SvgBudgetChart < ActionView::TestCase
    def build_budget(category_amounts)
      budget = Budget.create!(starts_at: 1.month.ago)
      category_amounts.each do |category, amount|
        BudgetCategory.create!(budget: budget, category: category, amount: amount)
      end
      budget
    end

    test "returns empty paragraph when no budget is given" do
      result = svg_budget_chart(budget: nil, debit_transactions: {}, credit_transactions: {})
      assert_equal content_tag(:p, ""), result
    end

    test "renders an SVG element when budget exists" do
      budget = build_budget(categories(:groceries) => 200)
      result = svg_budget_chart(
        budget: budget,
        debit_transactions: { categories(:groceries) => 150 },
        credit_transactions: {}
      )
      assert_match(/<svg/, result)
    end

    test "renders green bar when credit category is under 80% of budget" do
      budget = build_budget(categories(:income) => 1000)
      result = svg_budget_chart(
        budget: budget,
        debit_transactions: {},
        credit_transactions: { categories(:income) => 700 }
      )
      assert_match(/green/, result)
    end

    test "renders red bar when credit category exceeds budget" do
      budget = build_budget(categories(:income) => 100)
      result = svg_budget_chart(
        budget: budget,
        debit_transactions: {},
        credit_transactions: { categories(:income) => 200 }
      )
      assert_match(/red/, result)
    end

    test "renders grey bar for categories without a budget line" do
      budget = build_budget(categories(:groceries) => 200)
      result = svg_budget_chart(
        budget: budget,
        debit_transactions: { categories(:housing) => 500 },
        credit_transactions: {}
      )
      assert_match(/grey|gray|#888|muted/, result)
    end
  end
end
