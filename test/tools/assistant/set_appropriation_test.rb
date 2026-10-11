require "test_helper"

class Assistant::SetAppropriationTest < ActiveSupport::TestCase
  test "call selects a case-insensitive person and refuses an unknown recipient" do
    Assistant::SetAppropriation.call(
      purpose: "Birthday", recipient: "ETIENNE", budget_year: 2026, amount: 175, server_context: nil
    )
    appropriation = Appropriation.find_by!(purpose: "Birthday", budget_year: 2026, person: people(:etienne))

    assert_equal "Etienne", appropriation.recipient

    response = Assistant::SetAppropriation.call(
      purpose: "Birthday", recipient: "Nobody", budget_year: 2026, amount: 25, server_context: nil
    )

    assert_predicate response, :isError
    assert_not Appropriation.exists?(purpose: "Birthday", budget_year: 2026, recipient: "Nobody")
  end
end
