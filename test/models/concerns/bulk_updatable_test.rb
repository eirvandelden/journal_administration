require "test_helper"

class BulkUpdatableTest < ActiveSupport::TestCase
  test "update_uncategorized_transactions! updates transactions without category" do
    account = accounts(:checking)

    count = account.update_uncategorized_transactions!

    assert count >= 0
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
end
