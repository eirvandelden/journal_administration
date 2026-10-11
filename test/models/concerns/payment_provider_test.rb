require "test_helper"

class PaymentProviderTest < ActiveSupport::TestCase
  setup do
    @provider = accounts(:adyen)
    @provider.update!(payment_provider: true)
  end

  test "a family account cannot be a payment provider" do
    family = accounts(:checking)

    assert_not family.update(payment_provider: true)
    assert_includes family.errors[:payment_provider], I18n.t(
      "activerecord.errors.models.account.attributes.payment_provider.must_be_external"
    )
  end

  test "a family account refused as payment provider is named in the user's language" do
    family = accounts(:checking)

    I18n.with_locale(:nl) { family.update(payment_provider: true) }

    assert_equal "Betaaldienstverlener moet een externe rekening zijn",
      I18n.with_locale(:nl) { family.errors.full_messages.first }
  end

  test "counterparty_for returns the account itself when it is not a provider" do
    @provider.update!(payment_provider: false)

    assert_equal @provider, @provider.counterparty_for(described("Kruidvat"))
  end

  test "counterparty_for reads the merchant up to the next ING label" do
    assert_equal accounts(:kruidvat), @provider.counterparty_for(described("Kruidvat"))
  end

  test "counterparty_for reads a merchant followed directly by IBAN" do
    description = "Naam: Kruidvat IBAN: NL04ADYB2017400157 Kenmerk: 1"

    assert_equal accounts(:kruidvat), @provider.counterparty_for(description)
  end

  test "counterparty_for drops a via or by suffix in any case" do
    { "Partydeco via Stichting Mollie Payments" => "Partydeco", "Topbloemen BY Buckaroo" => "Topbloemen" }
      .each do |written, merchant|
      assert_equal merchant, @provider.counterparty_for(described(written)).name
    end
  end

  test "counterparty_for drops only the last via or by clause" do
    assert_equal "Flowers by Nature", @provider.counterparty_for(described("Flowers by Nature via Mollie")).name
  end

  test "counterparty_for stays on the provider without a Naam field" do
    assert_equal @provider, @provider.counterparty_for("Omschrijving: Payment IBAN: NL04ADYB2017400157")
    assert_equal @provider, @provider.counterparty_for(nil)
  end

  test "counterparty_for stays on the provider for its own name or an alias, in any case" do
    @provider.account_aliases.create!(pattern: "Adyen N.V.")

    [ "Adyen", "ADYEN", "adyen n.v." ].each do |name|
      assert_equal @provider, @provider.counterparty_for(described(name))
    end
  end

  test "counterparty_for stays on the provider for a name left empty by the suffix" do
    assert_equal @provider, @provider.counterparty_for(described("via Stichting Mollie Payments"))
  end

  test "counterparty_for prefers an alias over a name match" do
    Account.create!(name: "Kruidvat Amsterdam")

    assert_equal accounts(:kruidvat), @provider.counterparty_for(described("Kruidvat Amsterdam"))
  end

  test "counterparty_for stays on the provider when its own alias is the best match inside a longer name" do
    @provider.account_aliases.create!(pattern: "Adyen Europe")

    assert_equal @provider, @provider.counterparty_for(described("Kruidvat Adyen Europe"))
  end

  test "counterparty_for picks the merchant when the merchant's alias is longer than the provider's" do
    @provider.account_aliases.create!(pattern: "shop")
    merchant = Account.create!(name: "Flowershop")
    merchant.account_aliases.create!(pattern: "flowershop")

    assert_equal merchant, @provider.counterparty_for(described("The Flowershop Utrecht"))
  end

  test "counterparty_for picks the oldest of two external accounts with the same name" do
    oldest = Account.create!(name: "Twin Shop")
    Account.create!(name: "Twin Shop")

    assert_equal oldest, @provider.counterparty_for(described("Twin Shop"))
  end

  test "counterparty_for matches an existing name case-insensitively" do
    picnic = Account.create!(name: "Picnic")

    assert_no_difference "Account.count" do
      assert_equal picnic, @provider.counterparty_for(described("PICNIC"))
    end
  end

  test "counterparty_for creates an external account for an unknown merchant" do
    assert_difference "Account.external.count", 1 do
      merchant = @provider.counterparty_for(described("Kirovanni/Foodticket"))

      assert_equal "Kirovanni/Foodticket", merchant.name
      assert_nil merchant.owner
    end
  end

  test "counterparty_for never resolves to a family account" do
    merchant = @provider.counterparty_for(described("Gezamenlijke Rekening"))

    assert_predicate merchant, :external?
    assert_not_equal accounts(:checking), merchant
  end

  test "move_transactions_to_merchants returns how many moved" do
    assert_equal 3, @provider.move_transactions_to_merchants
    assert_equal accounts(:kruidvat), transactions(:kruidvat_through_adyen).debitor
    assert_equal accounts(:kruidvat), transactions(:refund_through_adyen).creditor
  end

  test "move_transactions_to_merchants leaves a staying transaction unsaved" do
    stayer = transactions(:adyen_itself)
    stayer.update_column(:updated_at, 1.year.ago)

    @provider.move_transactions_to_merchants

    assert_equal @provider, stayer.reload.debitor
    assert_in_delta 1.year.ago, stayer.updated_at, 1.minute
  end

  test "move_transactions_to_merchants moves nothing on an unmarked account" do
    @provider.update!(payment_provider: false)

    assert_equal 0, @provider.move_transactions_to_merchants
    assert_equal @provider, transactions(:kruidvat_through_adyen).reload.debitor
  end

  test "move_transactions_to_merchants moves nothing the second time" do
    @provider.move_transactions_to_merchants

    assert_equal 0, @provider.move_transactions_to_merchants
  end

  test "move_transactions_to_merchants rolls back every move when one fails" do
    created_first, failing = break_a_move_after_a_new_merchant

    error = assert_no_difference "Account.count" do
      assert_raises(PaymentProvider::MoveFailed) { @provider.move_transactions_to_merchants }
    end

    assert_equal failing, error.payment
    assert_nil Account.find_by(name: "Brand New Shop")
    assert_equal @provider, created_first.reload.creditor
    assert_equal categories(:gifts), created_first.category
  end

  test "move_transactions_to_merchants leaves the failing transaction and its splits as they were" do
    _, failing = break_a_move_after_a_new_merchant

    assert_raises(PaymentProvider::MoveFailed) { @provider.move_transactions_to_merchants }

    assert_equal @provider, failing.reload.debitor
    assert_equal [ [ 10, categories(:bakery) ] ],
      failing.explicit_transaction_splits.map { |split| [ split.amount, split.category ] }
  end

  private

  # Makes the move create a new merchant first, then fail on a transaction whose splits exceed its amount
  def break_a_move_after_a_new_merchant
    created_first = transactions(:refund_through_adyen)
    created_first.update_columns(original_note: "Naam: Brand New Shop Omschrijving: x", booked_at: 1.day.ago)
    failing = transactions(:kruidvat_through_adyen)
    failing.update_column(:booked_at, 2.days.ago)
    failing.transaction_splits.create!(amount: 10, category: categories(:bakery))
    failing.update_column(:amount, 5)
    order = Transaction.by_account(@provider.id).ids

    assert_operator order.index(created_first.id), :<, order.index(failing.id), "the new merchant must come first"

    [ created_first, failing ]
  end

  def described(merchant)
    "Naam: #{merchant} Omschrijving: Payment IBAN: NL04ADYB2017400157 Kenmerk: 1"
  end
end
