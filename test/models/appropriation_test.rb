require "test_helper"

class AppropriationTest < ActiveSupport::TestCase
  class Validations < ActiveSupport::TestCase
    test "requires purpose, recipient, budget year and a positive amount" do
      appropriation = Appropriation.new(amount: 0)

      assert_not appropriation.valid?
      assert_equal %i[amount budget_year purpose recipient], appropriation.errors.attribute_names.sort
    end

    test "refuses a duplicate regardless of letter case" do
      duplicate = Appropriation.new(purpose: "birthday", recipient: "ETIENNE", budget_year: 2026, amount: 10)

      assert_not duplicate.valid?
    end

    test "allows the same purpose and recipient in another year" do
      later = Appropriation.new(purpose: "Birthday", recipient: "Etienne", budget_year: 2028, amount: 10)

      assert_predicate later, :valid?
    end

    test "refuses changing the year onto an existing purpose and recipient" do
      assert_not appropriations(:birthday_etienne).update(budget_year: 2027)
    end
  end

  class RecipientSuggestions < ActiveSupport::TestCase
    test ".recipient_suggestions lists household members but not the shared account" do
      suggestions = Appropriation.recipient_suggestions

      assert_includes suggestions, "Chiara"
      assert_not_includes suggestions, "Samen"
    end

    test ".recipient_suggestions adds earlier recipients once regardless of letter case" do
      Appropriation.create!(purpose: "Birthday", recipient: "Grandma", budget_year: 2026, amount: 40)
      Appropriation.create!(purpose: "Christmas", recipient: "grandma", budget_year: 2026, amount: 30)

      assert_equal 1, Appropriation.recipient_suggestions.count { |name| name.casecmp?("grandma") }
      assert_equal 1, Appropriation.recipient_suggestions.count { |name| name.casecmp?("etienne") }
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
end
