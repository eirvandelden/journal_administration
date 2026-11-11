require "test_helper"
require_relative "../test_helpers/appropriation_payments"

class HubQueriesTest < ActionDispatch::IntegrationTest
  include AppropriationPayments

  # Measured on 2026-11-11, the session lookup included
  PLANNEN_LANDING_QUERIES = 18

  setup { sign_in_as(users(:member)) }

  test "verwerken counts run once per request" do
    assert_queries_match(/SELECT COUNT/i, count: 3) { get hub_url(:processing) }
  end

  test "plannen landing query count is independent of appropriations" do
    charged_appropriation(0)

    assert_queries_count(PLANNEN_LANDING_QUERIES) { get hub_url(:planning) }

    9.times { |index| charged_appropriation(index + 1) }

    assert_queries_count(PLANNEN_LANDING_QUERIES) { get hub_url(:planning) }
  end

  private
    def charged_appropriation(index)
      appropriation = Appropriation.create!(purpose: "Charged #{index}", person: people(:etienne),
        budget_year: Date.current.year, amount: 5000)
      credit(1000, note: "charge #{index}").update!(appropriation:)
    end
end
