require "test_helper"

class MutationTest < ActiveSupport::TestCase
  class BelongsToAssociationsTest < MutationTest
    test "belongs to a journal_entry (Transaction)" do
      assert_instance_of Transaction, mutations(:credit_grocery_our).journal_entry
    end

    test "belongs to an account" do
      assert_instance_of Account, mutations(:credit_grocery_our).account
    end
  end

  class ValidationsTest < MutationTest
    test "invalid without amount" do
      mutation = Mutation.new(journal_entry: transactions(:credit_grocery), account: accounts(:checking))

      assert_not mutation.valid?
      assert_includes mutation.errors[:amount], "can't be blank"
    end

    test "valid with all required attributes" do
      mutation = Mutation.new(
        journal_entry: transactions(:credit_grocery),
        account: accounts(:checking),
        amount: -25.00
      )

      assert mutation.valid?
    end
  end

  class AmountSignTest < MutationTest
    test "amount can be negative" do
      assert mutations(:credit_grocery_our).amount.negative?
    end

    test "amount can be positive" do
      assert mutations(:credit_grocery_theirs).amount.positive?
    end
  end
end
