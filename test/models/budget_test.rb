require "test_helper"

class BudgetTest < ActiveSupport::TestCase
  class Validations < ActiveSupport::TestCase
    def setup
      BudgetCategory.delete_all
      Budget.delete_all
    end

    test "is invalid without starts_at" do
      budget = Budget.new(starts_at: nil)
      assert budget.invalid?
      assert budget.errors[:starts_at].any?
    end

    test "is invalid when ends_at is not after starts_at" do
      budget = Budget.new(starts_at: Time.current, ends_at: 1.day.ago)
      assert budget.invalid?
      assert budget.errors[:ends_at].any?
    end

    test "is valid with only starts_at" do
      budget = Budget.new(starts_at: Time.current)
      assert budget.valid?
    end

    test "is valid with starts_at and future ends_at" do
      budget = Budget.new(starts_at: 1.month.ago, ends_at: 1.month.from_now)
      assert budget.valid?
    end

    test "is invalid when ends_at overlaps a successor budget" do
      Budget.create!(starts_at: 2.months.from_now)

      budget = Budget.new(starts_at: 1.month.ago, ends_at: 3.months.from_now)
      assert budget.invalid?
      assert budget.errors[:ends_at].any?
    end

    test "is valid when ends_at is before successor starts_at" do
      Budget.create!(starts_at: 2.months.from_now)

      budget = Budget.new(starts_at: 1.month.ago, ends_at: 1.month.from_now)
      assert budget.valid?
    end
  end

  class DateNormalization < ActiveSupport::TestCase
    test "normalizes starts_at to beginning of day" do
      budget = Budget.new(starts_at: Time.current.noon)
      budget.valid?
      assert_equal budget.starts_at.to_date.beginning_of_day, budget.starts_at
    end

    test "normalizes ends_at to end of day" do
      budget = Budget.new(starts_at: 1.month.ago, ends_at: Time.current.noon)
      budget.valid?
      assert_in_delta budget.ends_at.to_date.end_of_day, budget.ends_at, 1.second
    end

    test "does not normalize nil ends_at" do
      budget = Budget.new(starts_at: Time.current)
      budget.valid?
      assert_nil budget.ends_at
    end
  end

  class Scopes < ActiveSupport::TestCase
    def setup
      BudgetCategory.delete_all
      Budget.delete_all
    end

    test "active scope returns budget where starts_at <= now and ends_at is nil" do
      budget = Budget.create!(starts_at: 1.month.ago)
      assert_includes Budget.active, budget
    end

    test "active scope returns budget where starts_at <= now and ends_at > now" do
      budget = Budget.create!(starts_at: 1.month.ago, ends_at: 1.month.from_now)
      assert_includes Budget.active, budget
    end

    test "active scope excludes future budget" do
      budget = Budget.create!(starts_at: 1.month.from_now)
      assert_not_includes Budget.active, budget
    end

    test "active scope excludes past budget" do
      budget = Budget.create!(starts_at: 2.months.ago, ends_at: 1.month.ago)
      assert_not_includes Budget.active, budget
    end

    test "future scope returns budget with starts_at in the future" do
      budget = Budget.create!(starts_at: 1.month.from_now)
      assert_includes Budget.future, budget
    end

    test "past scope returns budget with ends_at in the past" do
      budget = Budget.create!(starts_at: 2.months.ago, ends_at: 1.month.ago)
      assert_includes Budget.past, budget
    end
  end

  class Predicates < ActiveSupport::TestCase
    test "active? returns true for active budget" do
      budget = Budget.create!(starts_at: 1.month.ago)
      assert budget.active?
    end

    test "active? returns false for future budget" do
      budget = Budget.create!(starts_at: 1.month.from_now)
      assert_not budget.active?
    end

    test "future? returns true when starts_at is in the future" do
      budget = Budget.new(starts_at: 1.month.from_now)
      assert budget.future?
    end

    test "past? returns true when ends_at is in the past" do
      budget = Budget.new(starts_at: 3.months.ago, ends_at: 1.month.ago)
      assert budget.past?
    end

    test "past? returns false when ends_at is nil" do
      budget = Budget.new(starts_at: 1.month.ago, ends_at: nil)
      assert_not budget.past?
    end
  end

  class ChainInvariant < ActiveSupport::TestCase
    def setup
      BudgetCategory.delete_all
      Budget.delete_all
    end

    test "closes predecessor with nil ends_at when new budget is created" do
      predecessor = Budget.create!(starts_at: 2.months.ago)
      assert_nil predecessor.ends_at

      new_budget = Budget.create!(starts_at: 1.month.from_now)
      predecessor.reload
      expected_ends_at = (new_budget.starts_at.beginning_of_day - 1.day).end_of_day
      assert_in_delta expected_ends_at, predecessor.ends_at, 1.second
    end

    test "does not close predecessor that already has an ends_at before the new start" do
      predecessor = Budget.create!(starts_at: 3.months.ago, ends_at: 2.months.ago)
      original_ends_at = predecessor.ends_at

      Budget.create!(starts_at: 1.month.from_now)
      predecessor.reload
      assert_in_delta original_ends_at, predecessor.ends_at, 1.second
    end

    test "clamps predecessor whose future ends_at overlaps the new budget start" do
      predecessor = Budget.create!(starts_at: 2.months.ago, ends_at: 2.months.from_now)

      new_budget = Budget.create!(starts_at: 1.month.from_now)
      predecessor.reload

      expected = (new_budget.starts_at.beginning_of_day - 1.day).end_of_day
      assert_in_delta expected, predecessor.ends_at, 1.second
    end

    test "only one active budget exists after creating budget when predecessor has overlapping future ends_at" do
      Budget.create!(starts_at: 2.months.ago, ends_at: 2.months.from_now)
      Budget.create!(starts_at: 1.month.from_now)

      assert_equal 1, Budget.active.count
    end

    test "re-closes predecessor when starts_at is updated" do
      predecessor = Budget.create!(starts_at: 2.months.ago)
      new_budget = Budget.create!(starts_at: 1.month.from_now)

      predecessor.reload
      first_close = predecessor.ends_at

      new_budget.update!(starts_at: 2.months.from_now)
      predecessor.reload

      expected = (new_budget.starts_at.beginning_of_day - 1.day).end_of_day
      assert_in_delta expected, predecessor.ends_at, 1.second
      assert_not_equal first_close.to_i, predecessor.ends_at.to_i
    end

    test "destroy does not affect other budgets dates" do
      predecessor = Budget.create!(starts_at: 2.months.ago)
      new_budget = Budget.create!(starts_at: 1.month.from_now)
      predecessor.reload
      original_ends_at = predecessor.ends_at

      new_budget.destroy
      predecessor.reload
      assert_in_delta original_ends_at, predecessor.ends_at, 1.second
    end
  end

  class SuggestedAmounts < ActiveSupport::TestCase
    test "returns a Hash" do
      budget = Budget.new(starts_at: Time.current)
      assert_instance_of Hash, budget.suggested_amounts
    end

    test "returns keys that are all parent categories" do
      budget = Budget.new(starts_at: Time.current)
      budget.suggested_amounts.each_key do |category|
        assert_nil category.parent_category_id,
          "Expected #{category.name} to be a parent category but it has parent_category_id #{category.parent_category_id}"
      end
    end

    test "returns positive amounts" do
      budget = Budget.new(starts_at: Time.current)
      budget.suggested_amounts.each_value do |amount|
        assert_operator amount, :>, 0, "Expected suggested amount to be positive"
      end
    end

    test "scales to period length for a 30-day budget" do
      # For a 30-day budget, suggested amounts should be reasonable
      budget = Budget.new(starts_at: 1.month.ago, ends_at: Time.current)
      suggestions_30_day = budget.suggested_amounts

      # For a 60-day budget, amounts should be approximately double
      budget_60 = Budget.new(starts_at: 2.months.ago, ends_at: Time.current)
      suggestions_60_day = budget_60.suggested_amounts

      # If both have the same categories, 60-day amounts should be roughly larger
      common_cats = suggestions_30_day.keys & suggestions_60_day.keys
      if common_cats.any?
        cat = common_cats.first
        assert suggestions_60_day[cat] >= suggestions_30_day[cat],
          "Expected 60-day suggestion (#{suggestions_60_day[cat]}) to be >= 30-day suggestion (#{suggestions_30_day[cat]})"
      end
    end
  end
end
