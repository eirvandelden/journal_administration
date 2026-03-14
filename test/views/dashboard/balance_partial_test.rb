require "test_helper"
require "ostruct"

class Dashboard::BalancePartialTest < ActiveSupport::TestCase
  test "renders table rows without nested cells" do
    dashboard = OpenStruct.new(
      debit_transactions: { categories(:groceries) => 62.5 },
      credit_transactions: { categories(:income) => 3000 },
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
end
