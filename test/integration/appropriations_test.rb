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
      post appropriations_path,
        params: { appropriation: new_appropriation(purpose: "birthday", recipient: "etienne") }
    end

    assert_response :unprocessable_entity
    assert_match(/already/i, response.body)
  end

  test "setting an appropriation shows it on its budget year's page with its full amount unspent" do
    post appropriations_path, params: { appropriation: new_appropriation(recipient: "Michelle", amount: 150) }

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Michelle", 150, 0, 150
  end

  test "raising an appropriation raises its balance by the same amount" do
    patch appropriation_path(appropriations(:birthday_etienne)), params: { appropriation: { amount: 200 } }

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Etienne", 200, 0, 200
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

    assert_appropriation_row "Birthday", "Etienne", 150, 0, 150
  end

  test "the page shows this year's appropriations and totals unless another year is chosen" do
    travel_to Date.new(2026, 6, 15) do
      get appropriations_path

      assert_appropriation_row "Christmas", "Serena", 50, 0, 50
      assert_select "tfoot", text: /#{Regexp.escape(currency(450))}/

      get appropriations_path(year: 2027)

      assert_appropriation_row "Birthday", "Chiara", 60, 0, 60
      assert_select "tbody tr", text: /Serena/, count: 0
    end
  end

  test "an appropriation lists the payments and split parts charged to it" do
    appropriation = appropriations(:sinterklaas_chiara)
    part = transactions(:webshop_sinterklaas).transaction_splits.create!(
      amount: 60, category: categories(:gifts), note: "Sinterklaas present for Chiara"
    )
    part.update!(appropriation:)
    transactions(:gift_payment).update!(appropriation:)

    get appropriation_path(appropriation)

    assert_select "tr", text: /2026-11-28.*Sinterklaas present for Chiara.*#{Regexp.escape(currency(60))}/m
    assert_select "tr", text: /2026-11-20.*Birthday present.*#{Regexp.escape(currency(40))}/m
  end

  test "in Dutch the page is called Begrotingsposten" do
    sign_in_as(users(:admin))

    get appropriations_path

    assert_select "header nav a[href=?]", appropriations_path, text: /Begrotingsposten/
    assert_select "h1", text: /Begrotingsposten/
  end

  private

  def new_appropriation(purpose: "Birthday", recipient: "Etienne", budget_year: 2026, amount: 150)
    { purpose:, recipient:, budget_year:, amount: }
  end
end
