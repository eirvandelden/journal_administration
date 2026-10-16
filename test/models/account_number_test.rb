require "test_helper"

class AccountNumberTest < ActiveSupport::TestCase
  test "AccountNumber normalizes spaces and case" do
    number = AccountNumber.new(number: " nl46 ingb 0702 4933 68 ")

    assert_equal "NL46INGB0702493368", number.number
  end

  test "finds a number regardless of spaces and case" do
    found = AccountNumber.find_by(number: "nl00 abna 9999 999999")

    assert_equal account_numbers(:albert_heijn), found
  end

  test "refuses a blank number" do
    number = AccountNumber.new(account: accounts(:jumbo), number: "  ")

    assert_not number.valid?
    assert_not_empty number.errors[:number]
  end

  test "refuses a number of another account and names that account" do
    number = AccountNumber.new(account: accounts(:jumbo), number: account_numbers(:albert_heijn).number)

    assert_not number.valid?
    assert_includes number.errors[:number].to_sentence, accounts(:albert_heijn).name
  end

  test "refuses a number of another account even when typed with spaces and lower case" do
    number = AccountNumber.new(account: accounts(:jumbo), number: "nl00 abna 9999 999999")

    assert_not number.valid?
  end

  test "accepts a number the account already holds" do
    number = account_numbers(:albert_heijn)

    assert_predicate number, :valid?
  end
end
