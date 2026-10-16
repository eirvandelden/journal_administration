require "test_helper"
require_relative "../test_helpers/appropriation_payments"

class AppropriationTest < ActiveSupport::TestCase
  class Validations < ActiveSupport::TestCase
    test "refuses duplicate purpose person and year" do
      duplicate = Appropriation.new(purpose: "birthday", person: people(:etienne), budget_year: 2026, amount: 1000)

      assert_not duplicate.valid?
    end

    test "requires purpose, recipient, budget year and a positive amount" do
      appropriation = Appropriation.new(amount: 0)

      assert_not appropriation.valid?
      assert_equal %i[amount budget_year purpose recipient], appropriation.errors.attribute_names.sort
    end

    test "refuses a duplicate regardless of letter case" do
      duplicate = Appropriation.new(purpose: "birthday", person: people(:etienne), budget_year: 2026, amount: 1000)

      assert_not duplicate.valid?
    end

    test "allows the same purpose and recipient in another year" do
      later = Appropriation.new(purpose: "Birthday", person: people(:etienne), budget_year: 2028, amount: 1000)

      assert_predicate later, :valid?
    end

    test "refuses changing the year onto an existing purpose and recipient" do
      assert_not appropriations(:birthday_etienne).update(budget_year: 2027)
    end
  end

  test "sets the legacy recipient on create only" do
    appropriation = Appropriation.create!(
      purpose: "Graduation", person: people(:grandma), budget_year: 2026, amount: 2500
    )

    assert_equal "Grandma", appropriation.recipient

    appropriation.update!(person: people(:grandpa))

    assert_equal "Grandma", appropriation.reload.recipient
  end

  test "renaming a person preserves appropriation amount and charges" do
    appropriation = appropriations(:birthday_etienne)
    transactions(:gift_payment).update!(appropriation:)
    charged = appropriation.charged

    people(:etienne).update!(name: "E. van Delden")

    assert_equal 15000, appropriation.reload.amount
    assert_equal charged, appropriation.charged
  end

  class RecipientSuggestions < ActiveSupport::TestCase
    test ".recipient_suggestions lists household members but not the shared account" do
      suggestions = Appropriation.recipient_suggestions

      assert_includes suggestions, "Chiara"
      assert_not_includes suggestions, "Samen"
    end

    test ".recipient_suggestions adds earlier recipients once regardless of letter case" do
      Appropriation.create!(purpose: "Birthday", person: people(:grandma), budget_year: 2026, amount: 4000)
      Appropriation.create!(purpose: "Christmas", person: people(:grandma), budget_year: 2026, amount: 3000)

      assert_equal 1, Appropriation.recipient_suggestions.count { |name| name.casecmp?("grandma") }
      assert_equal 1, Appropriation.recipient_suggestions.count { |name| name.casecmp?("etienne") }
    end

    test ".recipient_suggestions sorts managed names ignoring letter case" do
      Appropriation.create!(purpose: "Birthday", person: people(:grandma), budget_year: 2026, amount: 4000)
      Appropriation.create!(purpose: "Christmas", person: people(:grandma), budget_year: 2026, amount: 3000)
      bob = Person.create!(name: "bob", household: false)
      Appropriation.create!(purpose: "Birthday", person: bob, budget_year: 2026, amount: 2000)

      suggestions = Appropriation.recipient_suggestions

      assert_includes suggestions, "Grandma"
      assert_not_includes suggestions, "grandma"
      assert_operator suggestions.index("bob"), :<, suggestions.index("Chiara")
    end
  end

  class Totals < ActiveSupport::TestCase
    include AppropriationPayments

    setup do
      @appropriation = appropriations(:birthday_etienne)
    end

    test "#charged adds charged credits and credit parts and subtracts debits" do
      credit(90, note: "Birthday present").update!(appropriation: @appropriation)
      debit(20, note: "Returned present").update!(appropriation: @appropriation)
      credit_part(amount: 60).update!(appropriation: @appropriation)

      assert_equal 13000, @appropriation.charged
    end

    test "#balance is appropriated minus charged" do
      credit(40, note: "Birthday present").update!(appropriation: @appropriation)

      assert_equal 11000, @appropriation.balance
    end

    test "#overspent? when balance is negative" do
      credit(90, note: "Birthday present").update!(appropriation: @appropriation)
      credit_part(amount: 100).update!(appropriation: @appropriation)

      assert_predicate @appropriation, :overspent?
      assert_not appropriations(:christmas_etienne).overspent?
    end

    test "#charges lists whole payments and split parts by payment date" do
      part = webshop_part(amount: 6000)
      part.update!(appropriation: @appropriation)
      transactions(:gift_payment).update!(appropriation: @appropriation)
      transactions(:large_gift_payment).update!(appropriation: @appropriation)

      assert_equal [ transactions(:large_gift_payment), transactions(:gift_payment), part ], @appropriation.charges
    end

    test "#charges lists a payment without a booking date last" do
      transactions(:gift_payment).update!(appropriation: @appropriation, booked_at: nil)
      transactions(:large_gift_payment).update!(appropriation: @appropriation)

      assert_equal [ transactions(:large_gift_payment), transactions(:gift_payment) ], @appropriation.charges
    end

    private

    def credit_part(amount:)
      credit(100, note: "Shared presents").transaction_splits.create!(amount:, category: categories(:gifts))
    end

    def webshop_part(amount:)
      transactions(:webshop_sinterklaas).transaction_splits.create!(amount:, category: categories(:gifts))
    end
  end

  test ".of_year keeps only that year" do
    assert_equal [ appropriations(:birthday_chiara_next_year), appropriations(:birthday_etienne_next_year) ].sort,
      Appropriation.of_year(2027).sort
  end

  test "cannot be destroyed while charged" do
    appropriation = appropriations(:birthday_etienne)
    transactions(:gift_payment).update!(appropriation:)

    assert_not appropriation.destroy
    assert Appropriation.exists?(appropriation.id)
  end

  class LegacyDuplicates < ActiveSupport::TestCase
    test "refuses a new appropriation that matches only a legacy duplicate row" do
      original = appropriations(:birthday_etienne)
      original.update_columns(legacy_duplicate: true)
      Appropriation.where.not(id: original.id).where(purpose: "Birthday", person_id: original.person_id,
        budget_year: 2026).delete_all
      duplicate = Appropriation.new(purpose: "Birthday", person: original.person, budget_year: 2026, amount: 1000)

      assert_not duplicate.valid?
      assert_includes duplicate.errors.attribute_names, :purpose
    end

    test "keeps an existing legacy pair updatable" do
      first, second = legacy_pair

      assert first.update(amount: 1100)
      assert second.update(amount: 1200)
    end

    test "refuses moving a legacy row onto another existing key" do
      first, second = legacy_pair
      Appropriation.where(id: first.id).update_all(legacy_duplicate: true)
      clash = Appropriation.create!(purpose: "Other", person: second.person, budget_year: 2026, amount: 500)

      assert_not clash.update(purpose: "Birthday")
      assert_includes clash.errors.attribute_names, :purpose
    end

    test "the database refuses two unflagged rows with the same key when validation is bypassed" do
      original = appropriations(:birthday_etienne)
      twin = Appropriation.new(purpose: "BIRTHDAY", recipient: "Etienne", person: original.person,
        budget_year: 2026, amount: 1000)

      assert_raises(ActiveRecord::RecordNotUnique) { twin.save!(validate: false) }
    end

    test "the database allows a flagged row beside an unflagged one" do
      original = appropriations(:birthday_etienne)
      twin = Appropriation.new(purpose: "BIRTHDAY", recipient: "Etienne", person: original.person,
        budget_year: 2026, amount: 1000, legacy_duplicate: true)

      assert_nothing_raised { twin.save!(validate: false) }
    end

    private

    def legacy_pair
      first = appropriations(:birthday_etienne)
      second = Appropriation.new(purpose: "BIRTHDAY", recipient: "Etienne", person: first.person,
        budget_year: 2026, amount: 2000, legacy_duplicate: true)
      second.save!(validate: false)
      [ first, second ]
    end
  end
end
