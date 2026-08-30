require "application_system_test_case"

class BudgetsTest < ApplicationSystemTestCase
  setup do
    @user = users(:member)
    @locale = @user.locale.to_sym
    sign_in_as(@user)
  end

  test "should create budget" do
    visit budgets_url
    click_on I18n.t("budgets.index.new_budget", locale: @locale)

    fill_in I18n.t("budgets.form.starts_at", locale: @locale), with: Date.new(2026, 9, 1)
    click_on I18n.t("helpers.submit.create", model: Budget.model_name.human, locale: @locale)

    assert_text I18n.t("budgets.create.success", locale: @locale)
  end

  test "should update budget" do
    visit edit_budget_url(budgets(:past_budget))

    fill_in I18n.t("budgets.form.ends_at", locale: @locale), with: Date.new(2026, 2, 15)
    click_on I18n.t("helpers.submit.update", model: Budget.model_name.human, locale: @locale)

    assert_text I18n.t("budgets.update.success", locale: @locale)
  end
end
