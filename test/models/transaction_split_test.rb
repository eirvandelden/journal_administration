require "test_helper"

class TransactionSplitTest < ActiveSupport::TestCase
  class AmountValidations < ActiveSupport::TestCase
    test "amount must be present" do
      split = TransactionSplit.new(financial_transaction: transactions(:debit_grocery), amount: nil)

      assert_not split.valid?
      assert_includes split.errors[:amount], "can't be blank"
    end

    test "amount must be greater than zero" do
      split = TransactionSplit.new(financial_transaction: transactions(:debit_grocery), amount: 0)

      assert_not split.valid?
      assert_includes split.errors[:amount], "must be greater than 0"
    end

    test "amount must not exceed transaction split_balance on create" do
      split = TransactionSplit.new(financial_transaction: transactions(:debit_grocery), amount: 999.99)

      assert_not split.valid?
      assert_includes split.errors[:amount], I18n.t("activerecord.errors.models.transaction_split.attributes.amount.exceeds_transaction")
    end

    test "amount within split_balance is valid on create" do
      split = TransactionSplit.new(
        financial_transaction: transactions(:uncategorized),
        category: categories(:supermarket),
        amount: 10.00
      )

      assert split.valid?
    end
  end

  class Associations < ActiveSupport::TestCase
    test "belongs to transaction" do
      assert_equal transactions(:debit_grocery), transaction_splits(:split_grocery_supermarket).financial_transaction
    end

    test "category is optional" do
      split = TransactionSplit.new(
        financial_transaction: transactions(:uncategorized),
        amount: 10.00,
        category: nil
      )

      assert split.valid?
    end

    test "belongs to category when set" do
      assert_equal categories(:supermarket), transaction_splits(:split_grocery_supermarket).category
    end
  end

  class AmountOnUpdate < ActiveSupport::TestCase
    test "amount can be updated within remaining balance" do
      split = transaction_splits(:split_grocery_supermarket)
      split.amount = 20.00

      assert split.valid?
    end

    test "amount cannot be updated to exceed transaction amount" do
      split = transaction_splits(:split_grocery_supermarket)
      split.amount = 999.99

      assert_not split.valid?
      assert_includes split.errors[:amount], I18n.t("activerecord.errors.models.transaction_split.attributes.amount.exceeds_transaction")
    end
  end
end
