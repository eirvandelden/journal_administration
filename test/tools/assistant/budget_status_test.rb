require "test_helper"

class Assistant::BudgetStatusTest < ActiveSupport::TestCase
  setup do
    BudgetCategory.delete_all
    Budget.delete_all
  end

  test "reports a plan of 1250 cents as 12.50" do
    budget = Budget.create!(starts_at: Time.zone.parse("2026-01-01"))
    BudgetCategory.create!(budget:, category: categories(:groceries), amount: 1250)

    response = Assistant::BudgetStatus.call(start_date: "2026-01-01", end_date: "2026-01-30", server_context: nil)

    assert_not response.error?
    assert_includes response.content.first[:text], "planned 12.50, spent 0.00, 12.50 left"
  end
end
