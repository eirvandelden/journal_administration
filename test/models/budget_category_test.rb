require "test_helper"

class BudgetCategoryTest < ActiveSupport::TestCase
  class Validations < ActiveSupport::TestCase
    def setup
      BudgetCategory.delete_all
      Budget.delete_all
      @budget = Budget.create!(starts_at: 1.month.ago)
    end

    test "is valid with valid attributes" do
      bc = BudgetCategory.new(budget: @budget, category: categories(:groceries), amount: 100.00)
      assert bc.valid?
    end

    test "is invalid without amount" do
      bc = BudgetCategory.new(budget: @budget, category: categories(:groceries), amount: nil)
      assert bc.invalid?
      assert bc.errors[:amount].any?
    end

    test "is invalid with amount of zero" do
      bc = BudgetCategory.new(budget: @budget, category: categories(:groceries), amount: 0)
      assert bc.invalid?
      assert bc.errors[:amount].any?
    end

    test "is invalid with negative amount" do
      bc = BudgetCategory.new(budget: @budget, category: categories(:groceries), amount: -10)
      assert bc.invalid?
      assert bc.errors[:amount].any?
    end

    test "is invalid when category is a child category" do
      bc = BudgetCategory.new(budget: @budget, category: categories(:supermarket), amount: 100)
      assert bc.invalid?
      assert bc.errors[:category].any?
    end

    test "is invalid when category is the transfer category" do
      bc = BudgetCategory.new(budget: @budget, category: categories(:transfer), amount: 100)
      assert bc.invalid?
      assert bc.errors[:category].any?
    end

    test "is valid when category is a parent category" do
      bc = BudgetCategory.new(budget: @budget, category: categories(:groceries), amount: 100)
      assert bc.valid?
    end

    test "is invalid when budget_id and category_id pair is not unique" do
      BudgetCategory.create!(budget: @budget, category: categories(:groceries), amount: 100)
      bc = BudgetCategory.new(budget: @budget, category: categories(:groceries), amount: 200)
      assert bc.invalid?
      assert bc.errors[:budget_id].any?
    end
  end
end
