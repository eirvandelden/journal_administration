require "test_helper"
require_relative "../test_helpers/appropriation_payments"

class HubQueriesTest < ActionDispatch::IntegrationTest
  include AppropriationPayments

  # Measured on 2026-11-11, the session lookup included
  PLANNEN_LANDING_QUERIES = 18
  # Measured on 2026-11-12 with one page of 20 open transactions, the session lookup included
  ALLES_QUERIES = 49
  # Measured on 2026-11-13, the session lookup included
  PROFIEL_LANDING_QUERIES = 2

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

  test "profiel landing runs no count query" do
    assert_queries_count(PROFIEL_LANDING_QUERIES) { get hub_url(:profile) }
    assert_queries_match(/SELECT COUNT/i, count: 0) { get hub_url(:profile) }
  end

  test "alles query count is bounded by the page" do
    open_transactions(25)

    assert_queries_count(ALLES_QUERIES) { get todo_url }

    open_transactions(15)

    assert_queries_count(ALLES_QUERIES) { get todo_url }
  end

  private
    def charged_appropriation(index)
      appropriation = Appropriation.create!(purpose: "Charged #{index}", person: people(:etienne),
        budget_year: Date.current.year, amount: 5000)
      credit(1000, note: "charge #{index}").update!(appropriation:)
    end

    # Booked in the future, so the open transactions fill the first page of Alles.
    def open_transactions(count)
      booked_at = 1.hour.from_now
      count.times do |index|
        Transaction.create!(amount: index + 1, booked_at: booked_at, interest_at: booked_at,
          debitor: accounts(:checking), creditor: accounts(:unknown), note: "Open #{index}")
      end
    end
end
