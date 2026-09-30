require "test_helper"
require_relative "../test_helpers/appropriation_assertions"

class AppropriationChargesTest < ActionDispatch::IntegrationTest
  include AppropriationAssertions

  setup do
    sign_in_as(users(:member))
  end

  test "a split payment cannot be charged as a whole" do
    split_webshop_payment

    charge transactions(:webshop_sinterklaas), to: appropriations(:birthday_etienne)

    assert_nil transactions(:webshop_sinterklaas).reload.appropriation
    assert_match(/part/i, flash[:alert])
  end

  test "a payment charged as a whole cannot be split" do
    payment = transactions(:gift_payment)
    payment.update!(appropriation: appropriations(:birthday_etienne))

    assert_no_difference "TransactionSplit.count" do
      post transaction_transaction_splits_url(payment),
        params: { transaction_split: { category_id: categories(:gifts).id, amount: 10 } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
    end

    assert_response :unprocessable_entity
    assert_match(/charge/i, response.body)
  end

  test "a transfer offers no charge" do
    transfer = transactions(:transfer_savings)

    get transaction_path(transfer)

    assert_response :success
    assert_select "form[action=?]", transaction_appropriation_charge_path(transfer), count: 0
  end

  test "charging a payment lowers the appropriation's balance by its amount" do
    charge transactions(:gift_payment), to: appropriations(:birthday_etienne)

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Etienne", 150, 40, 110
  end

  test "the parts of one split payment can be charged to different appropriations" do
    chiara_part, cosimo_part = split_webshop_payment

    charge_part chiara_part, to: appropriations(:sinterklaas_chiara)
    charge_part cosimo_part, to: appropriations(:sinterklaas_cosimo)

    get appropriations_path(year: 2026)

    assert_appropriation_row "Sinterklaas", "Chiara", 75, 60, 15
    assert_appropriation_row "Sinterklaas", "Cosimo", 75, 40, 35
  end

  test "a payment counts in the budget year of its appropriation, not the year it was paid" do
    charge transactions(:gift_payment), to: appropriations(:birthday_chiara_next_year)

    get appropriations_path(year: 2027)

    assert_appropriation_row "Birthday", "Chiara", 60, 40, 20

    get appropriations_path(year: 2026)

    assert_select "tfoot", text: /#{Regexp.escape(currency(450))}.*#{Regexp.escape(currency(0))}/m
  end

  test "charging a payment to another appropriation moves its amount there" do
    payment = transactions(:gift_payment)
    payment.update!(appropriation: appropriations(:birthday_etienne))

    charge payment, to: appropriations(:christmas_etienne)

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Etienne", 150, 0, 150
    assert_appropriation_row "Christmas", "Etienne", 100, 40, 60
  end

  test "removing a charge lowers the amount charged and keeps the payment" do
    payment = transactions(:gift_payment)
    payment.update!(appropriation: appropriations(:birthday_etienne))

    delete transaction_appropriation_charge_path(payment)

    assert Transaction.exists?(payment.id)

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Etienne", 150, 0, 150
  end

  test "a charged refund lowers the amount charged" do
    charge transactions(:large_gift_payment), to: appropriations(:birthday_etienne)
    charge transactions(:gift_refund), to: appropriations(:birthday_etienne)

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Etienne", 150, 70, 80
  end

  test "spending more than appropriated shows a negative balance marked as overspent" do
    charge bicycle_for_etienne, to: appropriations(:birthday_etienne)

    get appropriations_path(year: 2026)

    assert_appropriation_row "Birthday", "Etienne", 150, 180, -30
    assert_select "tbody tr mark", text: currency(-30)
  end

  test "a payment's page shows its appropriation, per part when split" do
    payment = transactions(:gift_payment)
    payment.update!(appropriation: appropriations(:birthday_etienne))
    chiara_part, = split_webshop_payment
    chiara_part.update!(appropriation: appropriations(:birthday_etienne))

    get transaction_path(payment)

    assert_select "dd", text: /Birthday Etienne 2026/

    get transaction_path(transactions(:webshop_sinterklaas))

    assert_select "li", text: /Sinterklaas present for Chiara.*Birthday Etienne 2026/m
  end

  private

  def charge(payment, to:)
    patch transaction_appropriation_charge_path(payment),
      params: { appropriation_charge: { appropriation_id: to.id } }
  end

  def charge_part(part, to:)
    patch transaction_transaction_split_appropriation_charge_path(part.financial_transaction, part),
      params: { appropriation_charge: { appropriation_id: to.id } }
  end

  def split_webshop_payment
    webshop = transactions(:webshop_sinterklaas)

    { "Chiara" => 60, "Cosimo" => 40 }.map do |name, amount|
      webshop.transaction_splits.create!(amount:, category: categories(:gifts), note: "Sinterklaas present for #{name}")
    end
  end

  def bicycle_for_etienne
    Transaction.create!(
      type: "Debit", debitor: accounts(:savings), creditor: accounts(:unknown), category: categories(:gifts),
      amount: 180, booked_at: Time.zone.local(2026, 10, 20, 12), interest_at: Time.zone.local(2026, 10, 20, 12),
      note: "Birthday bicycle with a basket"
    )
  end
end
