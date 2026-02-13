require "test_helper"

class AccountTest < ActiveSupport::TestCase
  # -- owner enum -------------------------------------------------------------

  test "owner enum defines all family members" do
    expected = { "samen" => 0, "etienne" => 1, "michelle" => 2, "serena" => 3, "cosimo" => 4, "chiara" => 5 }

    assert_equal expected, Account.owners
  end

  test "FAMILY_OWNERS matches owner enum keys" do
    assert_equal Account.owners.keys, Account::FAMILY_OWNERS
  end

  # -- validations ------------------------------------------------------------

  test "account_number must be unique" do
    duplicate = Account.new(account_number: accounts(:checking).account_number)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:account_number], "has already been taken"
  end

  test "account_number allows blank" do
    account = Account.new(name: "No Number")

    assert account.valid?
  end

  # -- associations -----------------------------------------------------------

  test "belongs_to category (optional)" do
    assert_equal categories(:groceries), accounts(:checking).category
  end

  test "category can be nil" do
    assert_nil accounts(:savings).category
    assert accounts(:savings).valid?
  end

  # -- to_s -------------------------------------------------------------------

  test "to_s returns name when present" do
    assert_equal "Gezamenlijke Rekening", accounts(:checking).to_s
  end

  test "to_s returns account_number when name is blank" do
    account = Account.new(account_number: "NL00TEST0000000001", name: "")

    assert_equal "NL00TEST0000000001", account.to_s
  end
end
