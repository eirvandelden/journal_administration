require "test_helper"

class BulkUpdatableTest < ActiveSupport::TestCase
  test "update_uncategorized_transactions! updates transactions without category" do
    account = accounts(:checking)

    count = account.update_uncategorized_transactions!

    assert_equal 2, count
  end

  test "update_uncategorized_transactions! raises when account has no category" do
    account = accounts(:savings) # no category

    assert_raises BulkUpdatable::MissingCategoryError do
      account.update_uncategorized_transactions!
    end
  end

  test "update_uncategorized_transactions! sets category on uncategorized debitor transactions" do
    account = accounts(:checking)
    uncategorized = transactions(:uncategorized)

    assert_nil uncategorized.category_id

    account.update_uncategorized_transactions!

    assert_equal account.category_id, uncategorized.reload.category_id
  end

  test "update_uncategorized_transactions! sets category on uncategorized creditor transactions" do
    account = accounts(:checking)
    uncategorized_credit = transactions(:uncategorized_credit)

    assert_nil uncategorized_credit.category_id

    account.update_uncategorized_transactions!

    assert_equal account.category_id, uncategorized_credit.reload.category_id
  end

  test "update_uncategorized_transactions! does not override manually set categories" do
    account = accounts(:checking)
    manually_categorized = transactions(:debit_grocery)

    # Verify that the transaction has a category different from the account's default
    assert_not_equal account.category_id, manually_categorized.category_id
    original_category_id = manually_categorized.category_id

    account.update_uncategorized_transactions!

    # The category should NOT change because it was manually set
    assert_equal original_category_id, manually_categorized.reload.category_id
  end
end
