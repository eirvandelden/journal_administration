require "application_system_test_case"

class BudgetsTest < ApplicationSystemTestCase
  setup do
    @user = users(:member)
    sign_in_as(@user)
  end

  test "saving a new budget lands on that budget's page" do
    starts_at = budgets(:future_budget).starts_at.to_date + 1.day

    visit budgets_url
    click_on I18n.t("budgets.index.new_budget", locale: @locale)

    fill_in I18n.t("budgets.form.starts_at", locale: @locale), with: starts_at
    click_on I18n.t("helpers.submit.create", model: Budget.model_name.human, locale: @locale)

    assert_no_text "Content missing"
    assert_current_path budget_path(Budget.order(:starts_at).last)
  end

  test "saving an edited budget lands on that budget's page" do
    budget = budgets(:past_budget)
    ends_at = budgets(:active_budget).starts_at.to_date - 1.day

    visit edit_budget_url(budget)

    fill_in I18n.t("budgets.form.ends_at", locale: @locale), with: ends_at
    click_on I18n.t("helpers.submit.update", model: Budget.model_name.human, locale: @locale)

    assert_no_text "Content missing"
    assert_current_path budget_path(budget)
  end

  test "suggesting amounts keeps you on the budget form" do
    budget = budgets(:active_budget)
    visit edit_budget_url(budget)

    click_on I18n.t("budgets.form.suggest_amounts", locale: @locale)

    assert_no_text "Content missing"
    assert_current_path edit_budget_path(budget)
  end
end
