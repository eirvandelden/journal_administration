require "test_helper"

class AccountableTest < ActiveSupport::TestCase
  test "debitor_is_us? returns true for family-owned debitor" do
    transaction = Transaction.new(debitor: accounts(:checking))

    assert_predicate transaction, :debitor_is_us?
  end

  test "debitor_is_us? returns false for external debitor" do
    transaction = Transaction.new(debitor: accounts(:albert_heijn))

    assert_not transaction.debitor_is_us?
  end

  test "creditor_is_us? returns true for family-owned creditor" do
    transaction = Transaction.new(creditor: accounts(:checking))

    assert_predicate transaction, :creditor_is_us?
  end

  test "creditor_is_us? returns false for external creditor" do
    transaction = Transaction.new(creditor: accounts(:albert_heijn))

    assert_not transaction.creditor_is_us?
  end

  test "both_accounts_are_ours? returns true when both are family" do
    transaction = Transaction.new(debitor: accounts(:checking), creditor: accounts(:savings))

    assert_predicate transaction, :both_accounts_are_ours?
  end

  test "both_accounts_are_ours? returns false when one is external" do
    transaction = Transaction.new(debitor: accounts(:checking), creditor: accounts(:albert_heijn))

    assert_not transaction.both_accounts_are_ours?
  end
end
