require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  class CollectionAssociationsTest < TransactionTest
    test "has many mutations" do
      assert_equal 2, transactions(:credit_grocery).mutations.count
    end

    test "has_many chattels" do
      assert_includes transactions(:credit_grocery).chattels, chattels(:one)
    end
  end

  class BelongsToAssociationsTest < TransactionTest
    test "belongs_to category (optional)" do
      assert_instance_of Category, transactions(:credit_grocery).category
    end

    test "category can be nil" do
      assert_nil transactions(:uncategorized_credit).category
    end
  end

  class ValidationsTest < TransactionTest
    test "invalid without booked_at" do
      transaction = Transaction.new(booked_at: nil)

      assert_not transaction.valid?
      assert_includes transaction.errors[:booked_at], "can't be blank"
    end

    test "valid when mutations sum to zero" do
      assert build_balanced_transaction(amount: 100).valid?
    end

    test "invalid when there are no mutations" do
      transaction = Transaction.new(booked_at: Time.current)

      assert_not transaction.valid?
      assert transaction.errors[:mutations].any?
    end

    test "invalid when there is only one mutation" do
      transaction = Transaction.new(booked_at: Time.current)
      transaction.mutations.build(account: accounts(:checking), amount: 50)

      assert_not transaction.valid?
      assert transaction.errors[:mutations].any?
    end

    test "invalid when mutations do not sum to zero" do
      transaction = Transaction.new(booked_at: Time.current)
      transaction.mutations.build(account: accounts(:checking), amount: 100)
      transaction.mutations.build(account: accounts(:albert_heijn), amount: 10)

      assert_not transaction.valid?
      assert transaction.errors[:mutations].any?
    end

    test "invalid when mutation amounts are missing without raising" do
      transaction = Transaction.new(booked_at: Time.current)
      transaction.mutations.build(account: accounts(:checking), amount: nil)
      transaction.mutations.build(account: accounts(:albert_heijn), amount: nil)

      assert_nothing_raised { assert_not transaction.valid? }
      assert_includes transaction.mutations.first.errors[:amount], "can't be blank"
      assert_includes transaction.mutations.second.errors[:amount], "can't be blank"
    end

    test "invalid when an internal transfer is given a non-transfer category" do
      transaction = transactions(:transfer_savings)
      transaction.category = categories(:supermarket)

      assert_not transaction.valid?
      assert_includes transaction.errors[:category],
        I18n.t("activerecord.errors.models.transaction.attributes.category.must_remain_transfer")
    end
  end

  class AccessorsTest < TransactionTest
    test "creditor returns account with positive mutation amount" do
      assert_equal accounts(:albert_heijn), transactions(:credit_grocery).creditor
    end

    test "debitor returns account with negative mutation amount" do
      assert_equal accounts(:checking), transactions(:credit_grocery).debitor
    end

    test "amount returns sum of positive mutations" do
      assert_equal 50.0, transactions(:credit_grocery).amount
    end
  end

  class TypeIconTest < TransactionTest
    test "transfer? returns true for family-to-family mutations regardless of category" do
      transaction = transactions(:transfer_savings)
      transaction.category = categories(:supermarket)

      assert transaction.transfer?
    end

    test "type_icon returns credit icon when family account receives money" do
      assert_equal "⬇️ 🟥", transactions(:debit_salary).type_icon
    end

    test "type_icon returns debit icon when family account sends money" do
      assert_equal "⬆️ 🟩", transactions(:credit_grocery).type_icon
    end

    test "type_icon returns transfer icon when both accounts are family-owned" do
      assert_equal "🔄 ◻️", transactions(:transfer_savings).type_icon
    end
  end

  class ScopesTest < TransactionTest
    test "ordered scope orders transactions by booked_at descending" do
      booked_dates = Transaction.ordered.map(&:booked_at)

      assert_equal booked_dates.sort.reverse, booked_dates
    end

    test "our_mutations returns only mutations for family-owned accounts" do
      transaction = transactions(:credit_grocery)
      mutations_for_family_accounts = transaction.our_mutations

      assert mutations_for_family_accounts.all? { |mutation| mutation.account.owner.present? }
      assert_equal 1, mutations_for_family_accounts.count
    end

    test "for_index preloads category and mutation accounts for transaction list rendering" do
      transactions_for_index = Transaction.for_index.limit(5).to_a

      assert transactions_for_index.all? { |transaction| transaction.association(:category).loaded? }
      assert transactions_for_index.all? { |transaction| transaction.association(:mutations).loaded? }
      assert transactions_for_index.flat_map(&:mutations).all? { |mutation| mutation.association(:account).loaded? }
    end
  end

  class DependencyRestrictionsTest < TransactionTest
    test "destroy is restricted when chattels exist" do
      transaction = transactions(:credit_grocery)

      assert_no_difference "Transaction.count" do
        assert_not transaction.destroy
      end

      assert_includes transaction.errors[:base], "Cannot delete record because dependent chattels exist"
    end
  end

  private

  def build_balanced_transaction(amount:)
    transaction = Transaction.new(booked_at: Time.current)
    transaction.mutations.build(account: accounts(:checking), amount: -amount)
    transaction.mutations.build(account: accounts(:albert_heijn), amount: amount)
    transaction
  end
end
