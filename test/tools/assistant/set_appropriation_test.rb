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

    assert_predicate response, :error?
    assert_not Appropriation.exists?(purpose: "Birthday", budget_year: 2026, recipient: "Nobody")
  end

  test "stores 12.5 as 1250 cents" do
    response = Assistant::SetAppropriation.call(
      purpose: "Birthday", recipient: "Etienne", budget_year: 2030, amount: 12.5, server_context: nil
    )

    assert_not response.error?
    assert_includes response.content.first[:text], "is set at 12.50."
    assert_equal 1250, Appropriation.find_by!(purpose: "Birthday", budget_year: 2030).amount
  end

  test "refuses an amount with a fraction of a cent" do
    response = Assistant::SetAppropriation.call(
      purpose: "Birthday", recipient: "Etienne", budget_year: 2030, amount: 12.345, server_context: nil
    )

    assert_predicate response, :error?
    assert_includes response.content.first[:text], "at most two decimals"
    assert_not Appropriation.exists?(budget_year: 2030)
  end
end
