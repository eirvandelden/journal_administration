require "test_helper"
require_relative "../test_helpers/appropriation_assertions"

class AppropriationsTest < ActionDispatch::IntegrationTest
  include AppropriationAssertions

  setup do
    sign_in_as(users(:member))
  end

  test "an appropriation of nothing is refused" do
    assert_no_difference "Appropriation.count" do
      post appropriations_path, params: { appropriation: new_appropriation(amount: 0) }
    end

    assert_response :unprocessable_entity
    assert_includes response.body, "must be greater than 0"
  end

  test "a second appropriation for the same purpose, recipient and year is refused regardless of letter case" do
    assert_no_difference "Appropriation.count" do
      post appropriations_path, params: {
        appropriation: new_appropriation(purpose: "birthday", recipient: "etienne")
      }
    end

    assert_response :unprocessable_entity
    assert_match(/already/i, response.body)
  end

  test "setting an appropriation shows it on its budget year's page with its full amount unspent" do
    post appropriations_path, params: { appropriation: new_appropriation(recipient: "Michelle", amount: 150) }

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Michelle", 15000, 0, 15000
  end

  test "an appropriation selects an outside person" do
    get new_appropriation_path

    assert_select "select[name='appropriation[person_id]'] option[value=?]", people(:grandma).id, text: "Grandma"

    post appropriations_path, params: {
      appropriation: { purpose: "Visit", person_id: people(:grandma).id, budget_year: 2026, amount: 40 }
    }

    appropriation = Appropriation.find_by!(purpose: "Visit")

    assert_equal people(:grandma), appropriation.person
  end

  test "a new appropriation requires an existing managed person" do
    assert_no_difference [ "Appropriation.count", "Person.count" ] do
      post appropriations_path, params: {
        appropriation: { purpose: "Visit", recipient: "Unmanaged stranger", budget_year: 2026, amount: 40 }
      }
    end

    assert_response :unprocessable_entity
  end

  test "renaming a recipient updates displayed appropriations without changing charges" do
    appropriation = appropriations(:birthday_etienne)
    transactions(:gift_payment).update!(appropriation:)
    amount = appropriation.amount
    charged = appropriation.charged

    people(:etienne).update!(name: "E. van Delden")
    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "E. van Delden", amount, charged, amount - charged
    assert_appropriation_row "Christmas", "E. van Delden", 10000, 0, 10000
    assert_equal amount, appropriation.reload.amount
    assert_equal charged, appropriation.charged
  end

  test "raising an appropriation raises its balance by the same amount" do
    patch appropriation_path(appropriations(:birthday_etienne)), params: { appropriation: { amount: 200 } }

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Etienne", 20000, 0, 20000
  end

  test "an appropriation with charges cannot be removed" do
    appropriation = appropriations(:birthday_etienne)
    transactions(:gift_payment).update!(appropriation:)

    delete appropriation_path(appropriation)

    assert Appropriation.exists?(appropriation.id)
    assert_predicate flash[:alert], :present?
  end

  test "an appropriation without charges can be removed" do
    delete appropriation_path(appropriations(:christmas_serena))

    get appropriations_path(year: 2026)

    assert_select "tbody tr", text: /Serena/, count: 0
  end

  test "an unspent balance does not raise next year's appropriation" do
    transactions(:large_gift_payment).update!(appropriation: appropriations(:birthday_etienne))
    transactions(:gift_payment).update!(appropriation: appropriations(:birthday_etienne))

    get appropriations_path(year: 2027)

    assert_appropriation_row "Birthday", "Etienne", 15000, 0, 15000
  end

  test "the year page shows one section per person and one grand total" do
    get appropriations_path(year: 2026)

    headings = css_select("tbody th[scope=rowgroup]").map { |heading| heading.text.strip }
    etienne = css_select("tbody").find { |body| body.at_css("th")&.text&.strip == "Etienne" }

    assert_equal %w[Chiara Cosimo Etienne Serena], headings
    assert_equal %w[Birthday Christmas], etienne.css("td:first-child").map { |cell| cell.text.strip }
    assert_select "thead th", text: Appropriation.human_attribute_name(:recipient), count: 0
    assert_select "tfoot", count: 1
    assert_select "tfoot", text: /#{Regexp.escape(currency(45000))}/
  end

  test "each person heading spans every column of the table" do
    get appropriations_path(year: 2026)

    columns = css_select("thead th").size
    spans = css_select("tbody th[scope=rowgroup]").map { |heading| heading["colspan"].to_i }

    assert_equal [ columns ] * spans.size, spans
  end

  test "the page shows this year's appropriations and totals unless another year is chosen" do
    travel_to Date.new(2026, 6, 15) do
      get appropriations_path

      assert_appropriation_row "Christmas", "Serena", 5000, 0, 5000
      assert_select "tfoot", text: /#{Regexp.escape(currency(45000))}/

      get appropriations_path(year: 2027)

      assert_appropriation_row "Birthday", "Chiara", 6000, 0, 6000
      assert_select "tbody tr", text: /Serena/, count: 0
    end
  end

  test "a year that is not a number shows this year's appropriations" do
    travel_to Date.new(2026, 6, 15) do
      [ "", "next" ].each do |year|
        get appropriations_path(year:)

        assert_appropriation_row "Christmas", "Serena", 5000, 0, 5000
      end
    end
  end

  test "the year page works out what is charged once per appropriation" do
    reads = split_part_reads { get appropriations_path(year: 2026) }

    assert_operator reads, :<=, 2 * Appropriation.of_year(2026).count
  end

  test "a year written with a leading zero is read as that year" do
    get appropriations_path(year: "02027")

    assert_appropriation_row "Birthday", "Chiara", 6000, 0, 6000
  end

  test "an appropriation lists the payments and split parts charged to it" do
    appropriation = appropriations(:sinterklaas_chiara)
    part = transactions(:webshop_sinterklaas).transaction_splits.create!(
      amount: 6000, category: categories(:gifts), note: "Sinterklaas present for Chiara"
    )
    part.update!(appropriation:)
    transactions(:gift_payment).update!(appropriation:)

    get appropriation_path(appropriation)

    assert_select "tr", text: /2026-11-28.*Sinterklaas present for Chiara.*#{Regexp.escape(currency(6000))}/m
    assert_select "tr", text: /2026-11-20.*Birthday present.*#{Regexp.escape(currency(4000))}/m
  end

  test "an appropriation lists a charged payment that has no booking date" do
    appropriation = appropriations(:birthday_etienne)
    transactions(:gift_payment).update!(appropriation:, booked_at: nil)

    get appropriation_path(appropriation)

    assert_response :success
    assert_select "tr", text: /-.*Birthday present/m
  end

  test "the new-appropriation form lists every managed person using their current name" do
    people(:etienne).update!(name: "E. van Delden")
    get new_appropriation_path

    assert_select "select[name='appropriation[person_id]'] option[value=?]", people(:etienne).id, text: "E. van Delden"
    assert_select "select[name='appropriation[person_id]'] option[value=?]", people(:chiara).id, text: "Chiara"
    assert_select "select[name='appropriation[person_id]'] option[value=?]", people(:grandma).id, text: "Grandma"
    assert_select "select[name='appropriation[person_id]'] option[value=?]", people(:grandpa).id, text: "Grandpa"
    assert_select "select[name='appropriation[person_id]'] option", text: "Samen", count: 0

    aunt = Person.create!(name: "Aunt", household: false)
    Appropriation.create!(purpose: "Birthday", person: aunt, budget_year: 2026, amount: 4000)
    get new_appropriation_path

    assert_select "select[name='appropriation[person_id]'] option[value=?]", aunt.id, text: "Aunt"
  end

  test "in Dutch the page is called Begrotingsposten" do
    sign_in_as(users(:admin))

    get appropriations_path

    assert_select "header nav a[href=?]", appropriations_path, text: /Begrotingsposten/
    assert_select "h1", text: /Begrotingsposten/
  end

  test "legacy_duplicate cannot be set through the form params" do
    post appropriations_path, params: {
      appropriation: new_appropriation(purpose: "Graduation").merge(legacy_duplicate: "1")
    }

    created = Appropriation.find_by!(purpose: "Graduation")

    assert_not created.legacy_duplicate
  end

  test "legacy_duplicate cannot be changed through update params" do
    appropriation = appropriations(:birthday_etienne)

    patch appropriation_path(appropriation), params: { appropriation: { amount: 151, legacy_duplicate: "1" } }

    assert_not appropriation.reload.legacy_duplicate
  end

  test "the index rows carry no buttons and the purpose links to the appropriation" do
    travel_to Date.new(2026, 6, 15) do
      get appropriations_path
    end

    assert_select "tbody button", count: 0
    assert_select "tbody td a[href='#{appropriation_path(appropriations(:christmas_serena))}']"
    assert_select "main > header nav a[href='#{new_appropriation_path}']", text: I18n.t("common.new")
  end

  test "the edit page ends in an action row with Verwijderen…" do
    appropriation = appropriations(:christmas_serena)

    get edit_appropriation_path(appropriation)

    assert_select "form > footer button.button-danger[form='#{dom_id(appropriation, :delete)}']"
    assert_select "form##{dom_id(appropriation, :delete)}[action='#{appropriation_path(appropriation)}']"
  end

  test "the show page has no delete button" do
    get appropriation_path(appropriations(:christmas_serena))

    assert_select "button.button-danger", count: 0
  end

  test "a refused delete returns to the edit page with the reason" do
    appropriation = appropriations(:birthday_etienne)
    transactions(:gift_payment).update!(appropriation:)

    delete appropriation_path(appropriation)

    assert_redirected_to edit_appropriation_path(appropriation)
    assert_predicate flash[:alert], :present?
  end

  private

  # How many queries read split parts while the block runs
  def split_part_reads(&)
    reads = 0
    counter = ->(*, payload) { reads += 1 if payload[:sql].include?("transaction_splits") }
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    reads
  end

  def new_appropriation(purpose: "Birthday", recipient: "Etienne", budget_year: 2026, amount: 150)
    { purpose:, person_id: Person.find_by!(name_key: recipient.downcase).id, budget_year:, amount: }
  end
end
