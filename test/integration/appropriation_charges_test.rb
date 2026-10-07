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

    get edit_transaction_path(transfer)

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

  test "a payment's page shows its appropriation, per part when split, without a way to change it" do
    payment = transactions(:gift_payment)
    payment.update!(appropriation: appropriations(:birthday_etienne))
    chiara_part, = split_webshop_payment
    chiara_part.update!(appropriation: appropriations(:birthday_etienne))

    get transaction_path(payment)

    assert_select "dd", text: /Birthday Etienne 2026/
    assert_select "form[action=?]", transaction_appropriation_charge_path(payment), count: 0

    get transaction_path(chiara_part.financial_transaction)

    assert_select "li", text: /Sinterklaas present for Chiara.*Birthday Etienne 2026/m
    assert_select "form[action=?]",
      transaction_transaction_split_appropriation_charge_path(chiara_part.financial_transaction, chiara_part), count: 0
  end

  test "charging an unsplit payment on its edit page makes it count there" do
    payment = transactions(:gift_payment)

    get edit_transaction_path(payment)

    assert_select "form[action=?]", transaction_appropriation_charge_path(payment)

    charge payment, to: appropriations(:birthday_etienne)

    assert_redirected_to edit_transaction_path(payment)
    assert_equal 40, appropriations(:birthday_etienne).charged
  end

  test "charging one part on a split payment's edit page counts only that part" do
    chiara_part, = split_webshop_payment
    webshop = chiara_part.financial_transaction

    get edit_transaction_path(webshop)

    webshop.explicit_transaction_splits.each do |part|
      assert_select "tr", text: /#{part.note}/ do
        assert_select "form[action=?]", transaction_transaction_split_appropriation_charge_path(webshop, part)
      end
    end

    charge_part chiara_part, to: appropriations(:sinterklaas_chiara)

    assert_redirected_to edit_transaction_path(webshop)
    assert_equal 60, appropriations(:sinterklaas_chiara).charged
  end

  test "a split payment's edit page offers no charge for the whole payment or its remainder" do
    webshop = transactions(:webshop_sinterklaas)
    webshop.transaction_splits.create!(amount: 60, category: categories(:gifts), note: "Sinterklaas present for Chiara")
    webshop.ensure_remainder_split

    get edit_transaction_path(webshop)

    assert_select "form[action=?]", transaction_appropriation_charge_path(webshop), count: 0
    assert_equal webshop.explicit_transaction_splits.count, css_select("form[action*='appropriation_charge']").size
  end

  test "splitting a payment on its edit page stops offering to charge it as a whole" do
    payment = transactions(:gift_payment)

    get edit_transaction_path(payment)

    assert_select "article#whole_payment_charge" do
      assert_select "h2", Appropriation.model_name.human
      assert_select "form[action=?]", transaction_appropriation_charge_path(payment)
    end

    post transaction_transaction_splits_url(payment),
      params: { transaction_split: { category_id: categories(:gifts).id, amount: 10 } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_turbo_stream action: :replace, target: "whole_payment_charge"
    assert_no_match transaction_appropriation_charge_path(payment), response.body
  end

  test "splitting a transfer never offers to charge it" do
    transfer = transactions(:transfer_savings)

    post transaction_transaction_splits_url(transfer),
      params: { transaction_split: { category_id: categories(:gifts).id, amount: 10 } },
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_no_match transaction_appropriation_charge_path(transfer), response.body
  end

  test "removing the last part on the edit page offers to charge the whole payment again" do
    part = transactions(:gift_payment).transaction_splits.create!(amount: 10, category: categories(:gifts))

    delete transaction_transaction_split_url(part.financial_transaction, part),
      headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_match transaction_appropriation_charge_path(part.financial_transaction), response.body
  end

  test "an uncharged payment's page proposes no appropriation" do
    get edit_transaction_path(transactions(:gift_payment))

    assert_select "select[name='appropriation_charge[appropriation_id]'] option[value='']"
    assert_select "select[name='appropriation_charge[appropriation_id]'] option[selected]", count: 0
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
