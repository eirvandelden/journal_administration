require "test_helper"

class AccountAliasTest < ActiveSupport::TestCase
  test "belongs to an account" do
    account_alias = account_aliases(:albert_heijn_ah)

    assert_equal accounts(:albert_heijn), account_alias.account
  end

  test "is invalid without a pattern" do
    account_alias = AccountAlias.new(account: accounts(:albert_heijn), pattern: "")

    assert_not account_alias.valid?
    assert_includes account_alias.errors[:pattern], "can't be blank"
  end

  test "is invalid with a duplicate pattern for the same account" do
    duplicate = AccountAlias.new(account: accounts(:albert_heijn), pattern: "AH ")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:pattern], "has already been taken"
  end

  test "is invalid with a duplicate pattern for a different account" do
    account_alias = AccountAlias.new(account: accounts(:checking), pattern: "AH ")

    assert_not account_alias.valid?
    assert_includes account_alias.errors[:pattern], "has already been taken"
  end

  test "is invalid with a duplicate pattern that only differs by case" do
    account_alias = AccountAlias.new(account: accounts(:checking), pattern: "ah ")

    assert_not account_alias.valid?
    assert_includes account_alias.errors[:pattern], "has already been taken"
  end

  test "is invalid with percent wildcard in pattern" do
    account_alias = AccountAlias.new(account: accounts(:albert_heijn), pattern: "%")

    assert_not account_alias.valid?
    assert account_alias.errors[:pattern].any?
  end

  test "is invalid for a family account" do
    account_alias = AccountAlias.new(account: accounts(:checking), pattern: "Shared")

    assert_not account_alias.valid?
    assert_includes account_alias.errors[:account], I18n.t("activerecord.errors.models.account_alias.attributes.account.must_be_external")
  end

  test "is invalid with underscore wildcard in pattern" do
    account_alias = AccountAlias.new(account: accounts(:albert_heijn), pattern: "SHOP_X")

    assert_not account_alias.valid?
    assert account_alias.errors[:pattern].any?
  end
end
