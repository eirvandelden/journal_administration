require "application_system_test_case"

class BudgetsTest < ApplicationSystemTestCase
  TURBO_FRAME_MISSING_TEXT = "Content missing"

  setup do
    @user = users(:member)
    sign_in_as(@user)
  end

  test "saving a new budget lands on that budget's page" do
    starts_at = budgets(:future_budget).starts_at.to_date + 1.day
    ends_at = starts_at + 6.days

    visit budgets_url
    click_on I18n.t("budgets.index.new_budget", locale: locale)

    fill_in I18n.t("budgets.form.starts_at", locale: locale), with: starts_at
    fill_in I18n.t("budgets.form.ends_at", locale: locale), with: ends_at
    click_on I18n.t("helpers.submit.create", model: Budget.model_name.human, locale: locale)

    assert_current_path %r{\A/budgets/\d+\z}
    assert_current_path budget_path(Budget.find_by!(starts_at: starts_at.beginning_of_day))
    assert_no_text TURBO_FRAME_MISSING_TEXT
  end

  test "saving an edited budget lands on that budget's page" do
    budget = budgets(:past_budget)
    ends_at = budgets(:active_budget).starts_at.to_date - 1.day

    visit edit_budget_url(budget)

    fill_in I18n.t("budgets.form.ends_at", locale: locale), with: ends_at
    click_on I18n.t("helpers.submit.update", model: Budget.model_name.human, locale: locale)

    assert_current_path budget_path(budget)
    assert_no_text TURBO_FRAME_MISSING_TEXT
  end

  test "adding a category row includes it when the budget is saved" do
    starts_at = budgets(:future_budget).starts_at.to_date + 8.days
    ends_at = starts_at + 6.days

    visit budgets_url
    click_on I18n.t("budgets.index.new_budget", locale: locale)

    fill_in I18n.t("budgets.form.starts_at", locale: locale), with: starts_at
    fill_in I18n.t("budgets.form.ends_at", locale: locale), with: ends_at
    click_on I18n.t("budgets.form.add_category", locale: locale)

    assert_selector "[data-budget-categories-target='row']", count: 2

    within all("[data-budget-categories-target='row']").last do
      select categories(:groceries).name
      fill_in I18n.t("budgets.form.amount", locale: locale), with: "150.00"
    end
    click_on I18n.t("helpers.submit.create", model: Budget.model_name.human, locale: locale)

    assert_text I18n.t("budgets.create.success", locale: locale)

    assert_equal [ categories(:groceries) ], Budget.find_by!(starts_at: starts_at.beginning_of_day).categories
  end

  test "removing a category row leaves it out when the budget is saved" do
    starts_at = budgets(:future_budget).starts_at.to_date + 15.days
    budget = Budget.create!(starts_at: starts_at, ends_at: starts_at + 6.days)
    BudgetCategory.create!(budget: budget, category: categories(:groceries), amount: 100)

    visit edit_budget_url(budget)

    within first("[data-budget-categories-target='row']") do
      click_on I18n.t("budgets.form.remove", locale: locale)
    end
    click_on I18n.t("helpers.submit.update", model: Budget.model_name.human, locale: locale)

    assert_text I18n.t("budgets.update.success", locale: locale)

    assert_empty budget.reload.categories
  end

  test "suggesting amounts fills in historical averages" do
    starts_at = budgets(:future_budget).starts_at.to_date + 22.days
    budget = Budget.create!(starts_at: starts_at, ends_at: starts_at + 6.days)
    BudgetCategory.create!(budget: budget, category: categories(:groceries), amount: 200)
    BudgetCategory.create!(budget: budget, category: categories(:income), amount: 3000)

    visit edit_budget_url(budget)
    original_amounts = all("input[type=number]").map(&:value)

    click_on I18n.t("budgets.form.suggest_amounts", locale: locale)

    assert_current_path edit_budget_path(budget)
    assert_no_text TURBO_FRAME_MISSING_TEXT
    assert_selector "[data-budget-categories-target='row']", count: 3

    assert_not_equal original_amounts, all("input[type=number]").map(&:value)
  end
end
