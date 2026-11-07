require "test_helper"
require_relative "../test_helpers/appropriation_payments"

class NavigationHubsTest < ActionDispatch::IntegrationTest
  include AppropriationPayments

  setup do
    @member = users(:member)
    @member.update!(locale: :nl)
    sign_in_as(@member)
  end

  test "rail shows search, five hubs and the user name only" do
    get dashboard_index_url

    assert_select "nav.rail > ul > li", 7
    assert_select "nav.rail button[data-action='click->search-dialog#open']", text: I18n.t("search.open", locale: :nl)
    assert_equal [ "🏠 Overzicht", "📥 Verwerken", "🗓️ Plannen", "🗄️ Administratie", "🛒 Boodschappen" ],
      css_select("nav.rail > ul > li > a").map { |link| link.text.squish }
    assert_select "nav.rail > ul > li > details > summary", text: @member.name
  end

  test "categoriseren tile and badge count uncategorized transactions" do
    create_uncategorized_transactions(12)
    expected = Transaction.uncategorized.count

    get hub_url(:processing)

    assert_select "ul.tiles a[href=?]", transactions_path(filter: :no_category, from: :processing),
      text: /#{expected} transacties zonder categorie/
    assert_select "nav.hub-column a[href=?] data[value=?]", transactions_path(filter: :no_category), expected.to_s,
      text: expected.to_s
  end

  test "rekeningen indelen shows zero and no badge" do
    Account.update_all("updated_at = datetime(created_at, '+1 day')")

    get hub_url(:processing)

    assert_select "ul.tiles a[href=?]", accounts_path(filter: :untouched, from: :processing),
      text: /0 rekeningen nog niet ingedeeld/
    assert_select "nav.hub-column a[href=?] data", accounts_path(filter: :untouched), count: 0
  end

  test "transaction edit highlights administratie and journaal" do
    get edit_transaction_url(transactions(:debit_grocery))

    assert_select "nav.rail a[aria-current='true']", text: /Administratie/
    assert_select "nav.rail a[aria-current='true']", 1
    assert_select "nav.hub-column a[aria-current='page']", text: /Journaal/
  end

  test "budget show highlights plannen and budgetten" do
    get budget_url(budgets(:active_budget))

    assert_select "nav.rail a[aria-current='true']", text: /Plannen/
    assert_select "nav.hub-column a[aria-current='page']", text: /Budgetten/
  end

  test "bezittingen tile counts warranties ending within 90 days" do
    before = Chattel.warranty_ending.count
    Chattel.create!(name: "Washer", warranty_expires_at: 60.days.from_now)
    Chattel.create!(name: "Fridge", warranty_expires_at: 120.days.from_now)

    get hub_url(:records)

    assert_select "ul.tiles a[href=?]", chattels_path(filter: :warranty_ending, from: :records),
      text: /#{before + 1} bezitting(?:en)? waarvan de garantie binnen 90 dagen afloopt/
  end

  test "facturen tile counts and opens receipts without payment" do
    receipts(:albert_heijn_duplicate_monday).update!(payment: nil)

    get hub_url(:shopping)

    expected = Receipt.without_payment.count

    assert_select "ul.tiles a[href=?]", receipts_path(filter: :without_payment, from: :shopping),
      text: /#{expected} factu(?:ur|ren) zonder betaling/

    get receipts_url(filter: :without_payment)

    assert_select "#receipts-table tbody tr", expected
  end

  test "budgetten tile without active budget" do
    BudgetCategory.delete_all
    Budget.delete_all

    get hub_url(:planning)

    assert_select "ul.tiles a[href=?]", budgets_path(from: :planning), text: /Geen actief budget/
  end

  test "begrotingsposten tile counts and opens appropriations with money left" do
    before = Appropriation.of_year(Date.current.year).with_money_left.count
    open_one = Appropriation.create!(purpose: "Open", person: people(:etienne), budget_year: Date.current.year,
      amount: 5000)
    spent = Appropriation.create!(purpose: "Spent", person: people(:etienne), budget_year: Date.current.year,
      amount: 3000)
    credit(3000, note: "all of it").update!(appropriation: spent)

    get hub_url(:planning)

    assert_select "ul.tiles a[href=?]", appropriations_path(filter: :money_left, from: :planning),
      text: /#{before + 1} begrotingspo(?:st|sten) met geld over/
    assert_includes Appropriation.with_money_left, open_one
  end

  test "overzicht is the dashboard without hub column" do
    get dashboard_index_url

    assert_select "nav.rail a[aria-current='true']", text: /Overzicht/
    assert_select "nav.hub-column", 0
  end

  test "todo redirects to verwerken" do
    get todo_url

    assert_redirected_to hub_path(:processing)
  end

  test "member sees beheer without gebruikers" do
    get hub_url(:setup)

    assert_select "ul.tiles a[href=?]", categories_path(from: :setup)
    assert_select "ul.tiles a[href=?]", product_types_path(from: :setup)
    assert_select "ul.tiles a[href=?]", people_path(from: :setup)
    assert_select "ul.tiles a[href=?]", groups_path(from: :setup)
    assert_select "ul.tiles a[href=?]", admin_users_path(from: :setup), count: 0
    assert_select "nav.rail details a[href=?]", hub_path(:setup)
  end

  test "admin sees gebruikers and admin dashboard in the shell" do
    users(:admin).update!(locale: :nl)
    sign_in_as(users(:admin))

    get hub_url(:setup)

    assert_select "ul.tiles a[href=?]", admin_users_path(from: :setup)
    assert_select "ul.tiles a[href=?]", admin_root_path(from: :setup)
    assert_select "nav.rail details a[href=?]", hub_path(:setup)
  end

  test "show renders the tiles of a hub" do
    get hub_url(:records)

    assert_select "ul.tiles li", 3
  end

  test "show returns 404 for an unknown hub" do
    get hub_url("nope")

    assert_response :not_found
  end

  test "show returns 404 for the page-less overview hub" do
    get hub_url(:overview)

    assert_response :not_found
  end

  test "admin pages render the app shell" do
    sign_in_as(users(:admin))

    get admin_root_url

    assert_select "nav.rail"
    assert_select "nav.hub-column a[aria-current='page']", text: /Beheerdashboard/
  end

  test "preferences page renders the rail" do
    get edit_preferences_url

    assert_select "nav.rail"
  end

  test "verwerken counts run once per request" do
    queries = counting_queries { get hub_url(:processing) }

    assert_equal 3, queries.count { |sql| sql.match?(/SELECT COUNT/i) }
  end

  test "plannen landing query count is independent of appropriations" do
    one = counting_queries { get hub_url(:planning) }.size
    10.times { |index| charged_appropriation(index) }
    ten = counting_queries { get hub_url(:planning) }.size

    assert_equal one, ten
  end

  private
    def create_uncategorized_transactions(count)
      count.times do |index|
        Transaction.create!(amount: index + 1, booked_at: index.minutes.ago, interest_at: index.minutes.ago,
          debitor: accounts(:checking), creditor: accounts(:unknown), note: "Uncategorized #{index}")
      end
    end

    def charged_appropriation(index)
      appropriation = Appropriation.create!(purpose: "Charged #{index}", person: people(:etienne),
        budget_year: Date.current.year, amount: 5000)
      credit(1000, note: "charge #{index}").update!(appropriation:)
    end

    def counting_queries
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
        queries << payload[:sql] unless %w[SCHEMA TRANSACTION].include?(payload[:name])
      end
      yield
      queries
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
end
