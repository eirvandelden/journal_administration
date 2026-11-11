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

    assert_select "nav.rail > ul > li", 6
    assert_select "nav.rail > search:first-child > button[data-action='click->search-dialog#open']",
      text: I18n.t("search.open", locale: :nl)
    assert_equal [ "🏠 Overzicht", "📥 Verwerken", "🗓️ Plannen", "🗄️ Administratie", "🛒 Boodschappen" ],
      css_select("nav.rail > ul > li > a").map { |link| link.text.squish }
    assert_select "nav.rail > ul > li > details > summary", text: @member.name
  end

  test "categoriseren tile and badge count uncategorized transactions" do
    create_uncategorized_transactions(12)
    expected = Transaction.uncategorized.count

    get hub_url(:processing)

    assert_select "main > nav a[href=?]", transactions_path(filter: :no_category, from: :processing),
      text: /#{expected} transacties zonder categorie/
    assert_select "nav.rail + nav a[href=?] data[value=?]", transactions_path(filter: :no_category), expected.to_s,
      text: expected.to_s
  end

  test "rekeningen indelen shows zero and no badge" do
    Account.update_all("updated_at = datetime(created_at, '+1 day')")

    get hub_url(:processing)

    assert_select "main > nav a[href=?]", accounts_path(filter: :untouched, from: :processing),
      text: /0 rekeningen nog niet ingedeeld/
    assert_select "nav.rail + nav a[href=?] data", accounts_path(filter: :untouched), count: 0
  end

  test "transaction edit highlights administratie and journaal" do
    get edit_transaction_url(transactions(:debit_grocery))

    assert_select "nav.rail a[aria-current='true']", text: /Administratie/
    assert_select "nav.rail a[aria-current='true']", 1
    assert_select "nav.rail + nav a[aria-current='page']", text: /Journaal/
  end

  test "budget show highlights plannen and budgetten" do
    get budget_url(budgets(:active_budget))

    assert_select "nav.rail a[aria-current='true']", text: /Plannen/
    assert_select "nav.rail + nav a[aria-current='page']", text: /Budgetten/
  end

  test "bezittingen tile counts warranties ending within 90 days" do
    before = Chattel.warranty_ending.count
    Chattel.create!(name: "Washer", warranty_expires_at: 60.days.from_now)
    Chattel.create!(name: "Fridge", warranty_expires_at: 120.days.from_now)

    get hub_url(:records)

    assert_select "main > nav a[href=?]", chattels_path(filter: :warranty_ending, from: :records),
      text: /#{before + 1} bezitting(?:en)? waarvan de garantie binnen 90 dagen afloopt/
  end

  test "facturen tile counts and opens receipts without payment" do
    receipts(:albert_heijn_duplicate_monday).update!(payment: nil)

    get hub_url(:shopping)

    expected = Receipt.without_payment.count

    assert_select "main > nav a[href=?]", receipts_path(filter: :without_payment, from: :shopping),
      text: /#{expected} factu(?:ur|ren) zonder betaling/

    get receipts_url(filter: :without_payment)

    assert_select "#receipts-table tbody tr", expected
  end

  test "budgetten tile without active budget" do
    BudgetCategory.delete_all
    Budget.delete_all

    get hub_url(:planning)

    assert_select "main > nav a[href=?]", budgets_path(from: :planning), text: /Geen actief budget/
  end

  test "begrotingsposten tile counts and opens appropriations with money left" do
    before = Appropriation.of_year(Date.current.year).with_money_left.count
    open_one = Appropriation.create!(purpose: "Open", person: people(:etienne), budget_year: Date.current.year,
      amount: 5000)
    spent = Appropriation.create!(purpose: "Spent", person: people(:etienne), budget_year: Date.current.year,
      amount: 3000)
    credit(3000, note: "all of it").update!(appropriation: spent)

    get hub_url(:planning)

    assert_select "main > nav a[href=?]", appropriations_path(filter: :money_left, from: :planning),
      text: /#{before + 1} begrotingspo(?:st|sten) met geld over/
    assert_includes Appropriation.with_money_left, open_one
  end

  test "overzicht is the dashboard without hub column" do
    get dashboard_index_url

    assert_select "nav.rail a[aria-current='true']", text: /Overzicht/
    assert_select "nav.rail + nav", 0
  end

  test "todo redirects to verwerken" do
    get todo_url

    assert_redirected_to hub_path(:processing)
  end

  test "member sees beheer without gebruikers" do
    get hub_url(:setup)

    assert_select "main > nav a[href=?]", categories_path(from: :setup)
    assert_select "main > nav a[href=?]", product_types_path(from: :setup)
    assert_select "main > nav a[href=?]", people_path(from: :setup)
    assert_select "main > nav a[href=?]", groups_path(from: :setup)
    assert_select "main > nav a[href=?]", admin_users_path(from: :setup), count: 0
    assert_select "nav.rail details a[href=?]", hub_path(:setup)
  end

  test "admin sees gebruikers and admin dashboard in the shell" do
    users(:admin).update!(locale: :nl)
    sign_in_as(users(:admin))

    get hub_url(:setup)

    assert_select "main > nav a[href=?]", admin_users_path(from: :setup)
    assert_select "main > nav a[href=?]", admin_root_path(from: :setup)
    assert_select "nav.rail details a[href=?]", hub_path(:setup)
  end

  test "show renders the tiles of a hub" do
    get hub_url(:records)

    assert_select "main > nav > ul > li", 3
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
    assert_select "nav.rail + nav a[aria-current='page']", text: /Beheerdashboard/
  end

  test "preferences page renders the rail" do
    get edit_preferences_url

    assert_select "nav.rail"
  end

  test "only the overzicht title bar holds the avatar" do
    get dashboard_index_url

    assert_select "main > header nav details summary[aria-label=?]", @member.name, text: "👤"

    get hub_url(:processing)

    assert_select "main > header nav details", 0
  end

  test "every title bar holds a search button" do
    get hub_url(:processing)

    assert_select "main > header nav > search > button[data-action='click->search-dialog#open']"
  end

  private
    def create_uncategorized_transactions(count)
      count.times do |index|
        Transaction.create!(amount: index + 1, booked_at: index.minutes.ago, interest_at: index.minutes.ago,
          debitor: accounts(:checking), creditor: accounts(:unknown), note: "Uncategorized #{index}")
      end
    end
end
