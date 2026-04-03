require "test_helper"
require "ostruct"

class Dashboard::BalancePartialTest < ActiveSupport::TestCase
  test "renders table rows without nested cells" do
    dashboard = OpenStruct.new(
      debit_transactions: { categories(:groceries) => 62.5 },
      credit_transactions: { categories(:income) => 3000 },
      active_budget: nil,
      budget_amounts: {},
      debit_total: 62.5,
      credit_total: 3000,
      profit_or_loss: -2937.5
    )

    html = ApplicationController.render(
      partial: "dashboard/balance",
      locals: { dashboard: dashboard }
    )

    assert_no_match %r{<td>\s*<td}m, html
  end

  test "shows debit budget-only category when no matching debit transactions exist" do
    dashboard = OpenStruct.new(
      debit_transactions: {},
      credit_transactions: {},
      active_budget: OpenStruct.new,
      budget_amounts: { categories(:groceries) => 500 },
      debit_total: 0,
      credit_total: 0,
      profit_or_loss: 0
    )

    html = ApplicationController.render(
      partial: "dashboard/balance",
      locals: { dashboard: dashboard }
    )

    assert_match categories(:groceries).name, html
    assert_match "$500.00", html
  end

  test "shows credit budget-only category when no matching credit transactions exist" do
    dashboard = OpenStruct.new(
      debit_transactions: {},
      credit_transactions: {},
      active_budget: OpenStruct.new,
      budget_amounts: { categories(:income) => 3000 },
      debit_total: 0,
      credit_total: 0,
      profit_or_loss: 0
    )

    html = ApplicationController.render(
      partial: "dashboard/balance",
      locals: { dashboard: dashboard }
    )

    assert_match categories(:income).name, html
    assert_match "$3,000.00", html
  end
end
