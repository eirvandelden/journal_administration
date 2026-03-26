require "test_helper"

class BudgetHelperTest < ActionView::TestCase
  class BudgetStatus < ActionView::TestCase
    test "debit: returns green when actual is under 80% of budget" do
      assert_equal :green, budget_status(category: categories(:groceries), actual: 79, budgeted: 100)
    end

    test "debit: returns orange when actual is exactly 80% of budget" do
      assert_equal :orange, budget_status(category: categories(:groceries), actual: 80, budgeted: 100)
    end

    test "debit: returns orange when actual is between 80 and 100% of budget" do
      assert_equal :orange, budget_status(category: categories(:groceries), actual: 95, budgeted: 100)
    end

    test "debit: returns orange when actual equals budget" do
      assert_equal :orange, budget_status(category: categories(:groceries), actual: 100, budgeted: 100)
    end

    test "debit: returns red when actual exceeds budget" do
      assert_equal :red, budget_status(category: categories(:groceries), actual: 101, budgeted: 100)
    end

    test "debit: returns nil when budgeted is nil" do
      assert_nil budget_status(category: categories(:groceries), actual: 50, budgeted: nil)
    end

    test "debit: returns nil when budgeted is zero" do
      assert_nil budget_status(category: categories(:groceries), actual: 50, budgeted: 0)
    end

    test "credit: returns green when actual meets target" do
      assert_equal :green, budget_status(category: categories(:income), actual: 200, budgeted: 200)
    end

    test "credit: returns green when actual exceeds target" do
      assert_equal :green, budget_status(category: categories(:income), actual: 250, budgeted: 200)
    end

    test "credit: returns orange when actual is between 50 and 99% of target" do
      assert_equal :orange, budget_status(category: categories(:income), actual: 100, budgeted: 200)
    end

    test "credit: returns red when actual is under 50% of target" do
      assert_equal :red, budget_status(category: categories(:income), actual: 99, budgeted: 200)
    end
  end

  class BudgetPctLabel < ActionView::TestCase
    test "returns formatted percentage string" do
      assert_equal "73%", budget_pct_label(actual: 730, budgeted: 1000)
    end

    test "returns empty string when budgeted is nil" do
      assert_equal "", budget_pct_label(actual: 50, budgeted: nil)
    end

    test "returns empty string when budgeted is zero" do
      assert_equal "", budget_pct_label(actual: 50, budgeted: 0)
    end

    test "rounds to nearest integer" do
      assert_equal "67%", budget_pct_label(actual: 2, budgeted: 3)
    end
  end
end
