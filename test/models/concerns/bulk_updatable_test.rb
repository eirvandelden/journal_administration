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

  test "update_uncategorized_transactions! keeps manual categories for the updated account" do
    account = accounts(:albert_heijn)
    default_category = categories(:supermarket)
    manual_category = categories(:rent)

    default_transaction = create_transaction_with_mutations(
      debitor: accounts(:checking),
      creditor: account,
      amount: 10.00,
      category: default_category
    )

    manually_categorized_transaction = create_transaction_with_mutations(
      debitor: accounts(:checking),
      creditor: account,
      amount: 12.00,
      category: manual_category
    )

    count = account.update_uncategorized_transactions!

    assert_equal 0, count
    assert_equal default_category.id, default_transaction.reload.category_id
    assert_equal manual_category.id, manually_categorized_transaction.reload.category_id
  end

  private

  def create_transaction_with_mutations(debitor:, creditor:, amount:, category:)
    transaction = Transaction.new(
      booked_at: Time.current,
      interest_at: Time.current,
      category: category
    )
    transaction.mutations.build(account: debitor, amount: -amount)
    transaction.mutations.build(account: creditor, amount: amount)
    transaction.save!
    transaction
  end
end
