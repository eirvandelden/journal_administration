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

  test "GET /budgets/new renders the form inside a frame that navigates the whole page" do
    get new_budget_url

    assert_response :success
    assert_select "turbo-frame#budget_form[target=_top] form"
  end

  test "GET /budgets/new does not offer the transfer category" do
    get new_budget_url

    assert_response :success
    assert_select "option", text: categories(:transfer).name, count: 0
  end

  test "POST /budgets creates budget" do
    assert_difference "Budget.count", 1 do
      post budgets_url, params: {
        budget: { starts_at: "2025-06-01", ends_at: "2025-06-30" }
      }
    end
    assert_redirected_to budget_url(Budget.last)
  end

  test "POST /budgets ignores a blank prebuilt category row" do
    assert_difference "Budget.count", 1 do
      post budgets_url, params: {
        budget: {
          starts_at: "2025-06-01",
          ends_at: "2025-06-30",
          budget_categories_attributes: {
            "0" => { category_id: "", amount: "", _destroy: "false" }
          }
        }
      }
    end

    assert_equal 0, Budget.last.budget_categories.count
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
      budget: { ends_at: (budgets(:past_budget).ends_at.to_date + 1.day).to_s }
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

    assert_equal original_ends_at, active.ends_at
  end

  test "the index rows carry no buttons and the date range links to the budget" do
    get budgets_url

    assert_select "tbody button", count: 0
    assert_select "tbody td a[href='#{budget_path(budgets(:active_budget))}']"
    assert_select "main > header nav a[href='#{new_budget_path}']", text: I18n.t("common.new")
  end

  test "the edit page ends in an action row with Verwijderen… and keeps Bedragen voorstellen after it" do
    budget = budgets(:active_budget)

    get edit_budget_url(budget)

    assert_select "form > footer button.button-danger[form='#{dom_id(budget, :delete)}']"
    assert_select "form##{dom_id(budget, :delete)}[action='#{budget_path(budget)}']"
    assert_select "form > footer ~ p button[formaction='#{budget_suggestion_path(budget)}']"
  end

  test "the show page has no delete button and lists the period as a description list" do
    get budget_url(budgets(:active_budget))

    assert_select "button.button-danger", count: 0
    assert_select "main dl dt", minimum: 2
  end
end
