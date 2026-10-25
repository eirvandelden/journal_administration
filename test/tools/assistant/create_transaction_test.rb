require "test_helper"
require_relative "../../test_helpers/assistant_tool_calls"

class Assistant::CreateTransactionTest < ActiveSupport::TestCase
  include AssistantToolCalls

  test "creates a debit between our account and a shop" do
    response = create

    assert_not refused_response?(response)
    assert_equal "Debit", Transaction.find_by!(note: "Jumbo").type
  end

  test "passes on the books' refusal" do
    response = create(creditor_account_id: accounts(:unknown).id, debitor_account_id: accounts(:jumbo).id)

    assert refused_response?(response)
  end

  test "refuses an unknown account" do
    assert_includes said(create(creditor_account_id: 0)), "No account #0 exists"
  end

  private

  def create(**changes)
    Assistant::CreateTransaction.call(**{ debitor_account_id: accounts(:checking).id,
      creditor_account_id: accounts(:jumbo).id, amount: 4.20, booked_on: "2026-09-01", note: "Jumbo",
      server_context: nil }.merge(changes))
  end
end
