require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "household? reflects the household flag" do
    assert_predicate people(:etienne), :household?
    assert_not people(:grandma).household?
  end

  test "refuses to destroy account, appropriation, and membership references" do
    [ people(:etienne), people(:chiara), people(:michelle) ].each do |person|
      assert_not person.destroy
      assert Person.exists?(person.id)
    end

    account_only_person = Person.create!(name: "Account-only owner", household: false)
    Account.create!(name: "Account-only account", person: account_only_person)

    assert_not account_only_person.destroy
    assert Person.exists?(account_only_person.id)
  end

  test "refuses to drop household status from a used owner" do
    person = people(:etienne)

    assert_not person.update(household: false)
    assert_predicate person.reload, :household?
  end

  test "refuses to make an outside person a household owner when transactions depend on it" do
    account = Account.create!(name: "Grandma's account", owner: nil, person: people(:grandma))
    Debit.create!(
      amount: 25, booked_at: Time.current, interest_at: Time.current,
      debitor: accounts(:savings), creditor: account, category: categories(:gifts)
    )

    assert_not people(:grandma).update(household: true)
    assert_not_predicate people(:grandma).reload, :household?
  end

  test "allows making an outside person a household owner without transactions" do
    Account.create!(name: "Grandma's unused account", owner: nil, person: people(:grandma))

    assert people(:grandma).update(household: true)
    assert_predicate people(:grandma).reload, :household?
  end

  test "normalizes case-insensitive names" do
    Person.create!(name: "Élodie", household: false)
    duplicate = Person.new(name: "élodie", household: false)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "renaming preserves appropriation amounts and charges" do
    person = people(:etienne)
    appropriation = appropriations(:birthday_etienne)
    transactions(:gift_payment).update!(appropriation:)
    amount = appropriation.amount
    charged = appropriation.charged

    person.update!(name: "E. van Delden")

    assert_equal "E. van Delden", appropriation.reload.person.name
    assert_equal amount, appropriation.amount
    assert_equal charged, appropriation.charged
  end
end
