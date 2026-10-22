require "test_helper"

class BudgetsIndexTest < ActiveSupport::TestCase
  test "budget rows carry no delete button" do
    html = ApplicationController.render(
      template: "budgets/index",
      assigns: { budgets: [ budgets(:active_budget) ] }
    )

    assert_no_match "data-turbo-confirm", html
  end
end
