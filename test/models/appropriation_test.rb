require "test_helper"

class AppropriationTest < ActiveSupport::TestCase
  class Validations < ActiveSupport::TestCase
    test "refuses duplicate purpose person and year" do
      duplicate = Appropriation.new(purpose: "birthday", person: people(:etienne), budget_year: 2026, amount: 10)

      assert_not duplicate.valid?
    end

    test "requires purpose, recipient, budget year and a positive amount" do
      appropriation = Appropriation.new(amount: 0)

      assert_not appropriation.valid?
      assert_equal %i[amount budget_year purpose recipient], appropriation.errors.attribute_names.sort
    end

    test "refuses a duplicate regardless of letter case" do
      duplicate = Appropriation.new(purpose: "birthday", person: people(:etienne), budget_year: 2026, amount: 10)

      assert_not duplicate.valid?
    end

    test "allows the same purpose and recipient in another year" do
      later = Appropriation.new(purpose: "Birthday", person: people(:etienne), budget_year: 2028, amount: 10)

      assert_predicate later, :valid?
    end

    test "refuses changing the year onto an existing purpose and recipient" do
      assert_not appropriations(:birthday_etienne).update(budget_year: 2027)
    end
  end

  test "sets the legacy recipient on create only" do
    appropriation = Appropriation.create!(
      purpose: "Graduation", person: people(:grandma), budget_year: 2026, amount: 25
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

    assert_equal BigDecimal("150.00"), appropriation.reload.amount
    assert_equal charged, appropriation.charged
  end

  class RecipientSuggestions < ActiveSupport::TestCase
    test ".recipient_suggestions lists household members but not the shared account" do
      suggestions = Appropriation.recipient_suggestions

      assert_includes suggestions, "Chiara"
      assert_not_includes suggestions, "Samen"
    end

    test ".recipient_suggestions adds earlier recipients once regardless of letter case" do
      Appropriation.create!(purpose: "Birthday", person: people(:grandma), budget_year: 2026, amount: 40)
      Appropriation.create!(purpose: "Christmas", person: people(:grandma), budget_year: 2026, amount: 30)

      assert_equal 1, Appropriation.recipient_suggestions.count { |name| name.casecmp?("grandma") }
      assert_equal 1, Appropriation.recipient_suggestions.count { |name| name.casecmp?("etienne") }
    end

    test ".recipient_suggestions sorts managed names ignoring letter case" do
      Appropriation.create!(purpose: "Birthday", person: people(:grandma), budget_year: 2026, amount: 40)
      Appropriation.create!(purpose: "Christmas", person: people(:grandma), budget_year: 2026, amount: 30)
      bob = Person.create!(name: "bob", household: false)
      Appropriation.create!(purpose: "Birthday", person: bob, budget_year: 2026, amount: 20)

      suggestions = Appropriation.recipient_suggestions

      assert_includes suggestions, "Grandma"
      assert_not_includes suggestions, "grandma"
      assert_operator suggestions.index("bob"), :<, suggestions.index("Chiara")
    end
  end

  class Totals < ActiveSupport::TestCase
    setup do
      @appropriation = appropriations(:birthday_etienne)
    end

    test "#charged adds charged payments and split parts and subtracts refunds" do
      transactions(:large_gift_payment).update!(appropriation: @appropriation)
      transactions(:gift_refund).update!(appropriation: @appropriation)
      webshop_part(amount: 60).update!(appropriation: @appropriation)

      assert_equal BigDecimal("130"), @appropriation.charged
    end

    test "#balance is appropriated minus charged" do
      transactions(:gift_payment).update!(appropriation: @appropriation)

      assert_equal BigDecimal("110"), @appropriation.balance
    end

    test "#overspent? when balance is negative" do
      transactions(:large_gift_payment).update!(appropriation: @appropriation)
      webshop_part(amount: 100).update!(appropriation: @appropriation)

      assert_predicate @appropriation, :overspent?
      assert_not appropriations(:christmas_etienne).overspent?
    end

    test "#charges lists whole payments and split parts by payment date" do
      part = webshop_part(amount: 60)
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
      duplicate = Appropriation.new(purpose: "Birthday", person: original.person, budget_year: 2026, amount: 10)

      assert_not duplicate.valid?
      assert_includes duplicate.errors.attribute_names, :purpose
    end

    test "keeps an existing legacy pair updatable" do
      first, second = legacy_pair

      assert first.update(amount: 11)
      assert second.update(amount: 12)
    end

    test "refuses moving a legacy row onto another existing key" do
      _first, second = legacy_pair
      clash = Appropriation.create!(purpose: "Other", person: second.person, budget_year: 2026, amount: 5)

      assert_not clash.update(purpose: "Gift")
    end

    test "the database refuses two unflagged rows with the same key when validation is bypassed" do
      original = appropriations(:birthday_etienne)
      twin = Appropriation.new(purpose: "BIRTHDAY", recipient: "Etienne", person: original.person,
        budget_year: 2026, amount: 10)

      assert_raises(ActiveRecord::RecordNotUnique) { twin.save!(validate: false) }
    end

    test "the database allows a flagged row beside an unflagged one" do
      original = appropriations(:birthday_etienne)
      twin = Appropriation.new(purpose: "BIRTHDAY", recipient: "Etienne", person: original.person,
        budget_year: 2026, amount: 10, legacy_duplicate: true)

      assert_nothing_raised { twin.save!(validate: false) }
    end

    private

    def legacy_pair
      first = appropriations(:birthday_etienne)
      second = Appropriation.new(purpose: "BIRTHDAY", recipient: "Etienne", person: first.person,
        budget_year: 2026, amount: 20, legacy_duplicate: true)
      second.save!(validate: false)
      [ first, second ]
    end
  end
end
