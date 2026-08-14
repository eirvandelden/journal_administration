require "test_helper"

class BudgetsIndexTest < ActiveSupport::TestCase
  test "budget destroy button names its action in the confirm dialog" do
    html = ApplicationController.render(
      template: "budgets/index",
      assigns: { budgets: [ budgets(:active_budget) ] }
    )

    assert_match "data-confirm-verb", html
  end
end
