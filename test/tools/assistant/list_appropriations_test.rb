require "test_helper"
require_relative "../../test_helpers/appropriation_payments"

class Assistant::ListAppropriationsTest < ActiveSupport::TestCase
  include AppropriationPayments

  test "call uses current person name" do
    people(:etienne).update!(name: "E. van Delden")

    response = Assistant::ListAppropriations.call(budget_year: 2026, server_context: nil)

    assert_includes response.content.first[:text], "Birthday for E. van Delden"
    assert_not_includes response.content.first[:text], "Birthday for Etienne"
  end

  test "call reports charged as credits minus debits" do
    appropriation = appropriations(:birthday_etienne)
    appropriation.update!(amount: 20_000)
    credit(5_000, note: "Birthday present").update!(appropriation:)
    debit(2_000, note: "Returned present").update!(appropriation:)

    response = Assistant::ListAppropriations.call(budget_year: 2026, server_context: nil)
    line = response.content.first[:text].lines.find { |candidate| candidate.start_with?("#{appropriation.id}:") }

    assert_includes line, "charged 30.00, left 170.00"
  end

  test "reports amounts in euros as before" do
    response = Assistant::ListAppropriations.call(budget_year: 2026, server_context: nil)

    assert_includes response.content.first[:text], "appropriated 150.00"
  end
end
