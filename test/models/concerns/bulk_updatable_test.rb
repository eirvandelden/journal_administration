require "test_helper"

class BulkUpdatableTest < ActiveSupport::TestCase
  class UpdateUncategorizedTransactionsTest < BulkUpdatableTest
    test "updates transactions without category" do
      account = accounts(:checking)

      count = account.update_uncategorized_transactions!

      assert_equal 2, count
    end

    test "raises when account has no category" do
      account = accounts(:savings)

      assert_raises BulkUpdatable::MissingCategoryError do
        account.update_uncategorized_transactions!
      end
    end

    test "sets category on uncategorized credit transactions" do
      account = accounts(:checking)
      uncategorized_credit = transactions(:uncategorized_credit)

      assert_nil uncategorized_credit.category_id

      account.update_uncategorized_transactions!

      assert_equal account.category_id, uncategorized_credit.reload.category_id
    end

    test "sets category on uncategorized debit transactions" do
      account = accounts(:checking)
      uncategorized_debit = transactions(:uncategorized_debit)

      assert_nil uncategorized_debit.category_id

      account.update_uncategorized_transactions!

      assert_equal account.category_id, uncategorized_debit.reload.category_id
    end

    test "does not override manually set categories" do
      account = accounts(:checking)
      manually_categorized = transactions(:credit_grocery)
      original_category_id = manually_categorized.category_id

      assert_not_equal account.category_id, original_category_id

      account.update_uncategorized_transactions!

      assert_equal original_category_id, manually_categorized.reload.category_id
    end

    test "keeps manual categories for the updated account" do
      account = accounts(:albert_heijn)
      default_category = categories(:supermarket)
      manual_category = categories(:rent)

      default_transaction = transactions(:credit_albert_heijn_default_category)
      manually_categorized_transaction = transactions(:credit_albert_heijn_manual_category)

      count = account.update_uncategorized_transactions!

      assert_equal 0, count
      assert_equal default_category.id, default_transaction.reload.category_id
      assert_equal manual_category.id, manually_categorized_transaction.reload.category_id
    end
  end
end
