require "test_helper"

class Assistant::ListAppropriationsTest < ActiveSupport::TestCase
  test "call uses current person name" do
    people(:etienne).update!(name: "E. van Delden")

    response = Assistant::ListAppropriations.call(budget_year: 2026, server_context: nil)

    assert_includes response.content.first.text, "Birthday for E. van Delden"
    assert_not_includes response.content.first.text, "Birthday for Etienne"
  end
end
