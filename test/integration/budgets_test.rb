require "test_helper"

class BudgetsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:member))
  end

  test "GET /budgets lists all budgets" do
    get budgets_url
    assert_response :success
    assert_select "table"
  end

  test "GET /budgets/new renders form" do
    get new_budget_url
    assert_response :success
    assert_select "form"
  end

  test "POST /budgets creates budget" do
    assert_difference "Budget.count", 1 do
      post budgets_url, params: {
        budget: { starts_at: "2025-06-01", ends_at: "2025-06-30" }
      }
    end
    assert_redirected_to budget_url(Budget.last)
  end

  test "POST /budgets with nested budget_categories creates categories" do
    assert_difference [ "Budget.count", "BudgetCategory.count" ] do
      post budgets_url, params: {
        budget: {
          starts_at: "2025-06-01",
          ends_at: "2025-12-31",
          budget_categories_attributes: {
            "0" => { category_id: categories(:groceries).id, amount: "300.00" }
          }
        }
      }
    end
  end

  test "POST /budgets with invalid params renders new" do
    post budgets_url, params: { budget: { starts_at: "" } }
    assert_response :unprocessable_entity
  end

  test "GET /budgets/:id shows budget" do
    get budget_url(budgets(:active_budget))
    assert_response :success
  end

  test "GET /budgets/:id/edit renders edit form" do
    get edit_budget_url(budgets(:active_budget))
    assert_response :success
    assert_select "form"
  end

  test "PATCH /budgets/:id updates budget" do
    patch budget_url(budgets(:past_budget)), params: {
      budget: { ends_at: "2026-01-31" }
    }
    assert_redirected_to budget_url(budgets(:past_budget))
  end

  test "DELETE /budgets/:id destroys budget" do
    assert_difference "Budget.count", -1 do
      delete budget_url(budgets(:past_budget))
    end
    assert_redirected_to budgets_url
  end

  test "POST /budgets/:id/suggestion pre-fills amounts and renders edit form" do
    post budget_suggestion_url(budgets(:active_budget))
    assert_response :success
    assert_select "form"
  end

  test "PATCH /budgets/:id/suggestion keeps in-progress form dates" do
    patch budget_suggestion_url(budgets(:active_budget)), params: {
      budget: {
        starts_at: "2026-04-01",
        ends_at: "2026-04-30"
      }
    }

    assert_response :success
    assert_select "input[name='budget[starts_at]'][value='2026-04-01']"
    assert_select "input[name='budget[ends_at]'][value='2026-04-30']"
  end

  test "DELETE /budgets/:id does not affect other budgets dates" do
    active = budgets(:active_budget)
    original_ends_at = active.ends_at

    delete budget_url(budgets(:past_budget))

    active.reload
    assert_nil active.ends_at
  end
end
