require "test_helper"

class MutationTest < ActiveSupport::TestCase
  test "belongs to a journal_entry (Transaction)" do
    assert_instance_of Transaction, mutations(:debit_grocery_our).journal_entry
  end

  test "belongs to an account" do
    assert_instance_of Account, mutations(:debit_grocery_our).account
  end

  test "invalid without amount" do
    mutation = Mutation.new(journal_entry: transactions(:debit_grocery), account: accounts(:checking))
    assert_not mutation.valid?
    assert_includes mutation.errors[:amount], "can't be blank"
  end

  test "valid with all required attributes" do
    mutation = Mutation.new(
      journal_entry: transactions(:debit_grocery),
      account: accounts(:checking),
      amount: -25.00
    )
    assert mutation.valid?
  end

  test "amount can be negative" do
    assert mutations(:debit_grocery_our).amount.negative?
  end

  test "amount can be positive" do
    assert mutations(:debit_grocery_theirs).amount.positive?
  end
end
