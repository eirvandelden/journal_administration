require "test_helper"

class Assistant::SetBudgetAmountTest < ActiveSupport::TestCase
  test "stores 12.5 as 1250 cents" do
    budget = budgets(:active_budget)

    response = Assistant::SetBudgetAmount.call(
      budget_id: budget.id, category_id: categories(:housing).id, amount: 12.5, server_context: nil
    )

    assert_not response.error?
    assert_includes response.content.first[:text], "may cost 12.50 a month"
    assert_equal 1250, budget.budget_categories.find_by!(category: categories(:housing)).amount
  end

  test "refuses an amount with a fraction of a cent" do
    budget = budgets(:active_budget)

    response = Assistant::SetBudgetAmount.call(
      budget_id: budget.id, category_id: categories(:housing).id, amount: 12.345, server_context: nil
    )

    assert_predicate response, :error?
    assert_includes response.content.first[:text], "at most two decimals"
  end
end
