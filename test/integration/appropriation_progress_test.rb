require "test_helper"
require_relative "../test_helpers/appropriation_assertions"
require_relative "../test_helpers/appropriation_payments"

class AppropriationProgressTest < ActionDispatch::IntegrationTest
  include AppropriationAssertions
  include AppropriationPayments

  setup do
    sign_in_as(users(:member))
  end

  test "the list shows purpose, amount, a bar and what is left, and no Charged column" do
    get appropriations_path(year: 2026)

    headers = css_select("thead th").map { |header| header.text.strip }

    assert_equal [ Appropriation.human_attribute_name(:purpose), Appropriation.human_attribute_name(:amount),
      I18n.t("appropriations.index.used"), I18n.t("appropriations.index.balance") ], headers
    assert_not_includes headers, I18n.t("appropriations.show.charged")
    rows = css_select("tbody tr:has(td)")

    assert_not_empty rows
    rows.each { |row| assert_select row, "td:nth-child(3) progress", 1 }
  end

  test "an appropriation a quarter charged shows a bar a quarter full between its amount and what is left" do
    charge credit(2_500, note: "Present"), to: appropriations(:christmas_etienne)

    get appropriations_path(year: 2026)

    row = christmas_row

    assert_equal currency(10_000), row.css("td")[1].text.strip
    assert_equal 1, row.css("td")[2].css("progress[max='10000'][value='2500']").size
    assert_equal currency(7_500), row.css("td")[3].text.strip
  end

  test "an appropriation with nothing charged shows an empty bar" do
    get appropriations_path(year: 2026)

    assert_equal 1, christmas_row.css("progress[max='10000'][value='0']").size
  end

  test "an overspent appropriation shows a full bar and a balance, both marked as overspent" do
    charge credit(13_000, note: "Present"), to: appropriations(:christmas_etienne)

    get appropriations_path(year: 2026)

    cells = christmas_row.css("td")

    overspent = I18n.t("appropriations.balance.overspent")

    assert_equal 1, cells[2].css("mark[title='#{overspent}'] > progress[max='10000'][value='10000']").size
    assert_includes cells[2].at_css("progress")["aria-label"], currency(13_000)
    assert_equal 1, cells[3].css("mark").size
    assert_equal currency(-3_000), cells[3].text.strip
  end

  test "an appropriation with more refunded than charged shows an empty bar" do
    charge debit(2_000, note: "Refund"), to: appropriations(:christmas_etienne)

    get appropriations_path(year: 2026)

    bar = christmas_row.at_css("progress")

    assert_equal "0", bar["value"]
    assert_includes bar["aria-label"], currency(-2_000)
  end

  test "the total row shows a bar for everything charged against everything appropriated" do
    charge credit(2_500, note: "Present"), to: appropriations(:christmas_etienne)

    get appropriations_path(year: 2026)

    assert_select "tfoot progress[max='45000'][value='2500']"
  end

  test "the total row marks its bar when more is charged than appropriated in the year" do
    charge credit(70_000, note: "Present"), to: appropriations(:birthday_chiara_next_year)

    get appropriations_path(year: 2027)

    assert_select "tfoot mark > progress"
  end

  test "each appropriation adds only the queries that work out what is charged" do
    before = queries_run { get appropriations_path(year: 2026) }

    Appropriation.create!(purpose: "Birthday", person: people(:serena), budget_year: 2026, amount: 5_000)
    after = queries_run { get appropriations_path(year: 2026) }

    assert_equal 4, after - before
  end

  test "the show page shows the bar above its figures" do
    appropriation = appropriations(:christmas_etienne)
    charge credit(2_500, note: "Present"), to: appropriation

    get appropriation_path(appropriation)

    assert_select "article > progress[max='10000'][value='2500'] + dl"
    assert_appropriation_figures(2_500, 7_500)

    charge credit(10_000, note: "More"), to: appropriation
    get appropriation_path(appropriation)

    assert_select "article > mark > progress[value='10000']"
    assert_select "article > mark + dl"
  end

  private

  def christmas_row
    css_select("tbody tr:has(td)").find do |row|
      row.at_css("td a")&.text == "Christmas" && row.text.include?(currency(10_000))
    end
  end

  def charge(payment, to:)
    payment.update!(appropriation: to)
  end

  def queries_run(&)
    queries = 0
    counter = ->(*, payload) { queries += 1 unless payload[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    queries
  end
end
