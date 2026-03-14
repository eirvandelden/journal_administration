require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  # -- type validation --------------------------------------------------------

  test "valid types are Credit, Debit, and Transfer" do
    assert_includes Transaction::TYPES, "Credit"
    assert_includes Transaction::TYPES, "Debit"
    assert_includes Transaction::TYPES, "Transfer"
    assert_equal 3, Transaction::TYPES.size
  end

  test "type must be present" do
    transaction = Transaction.new(type: nil, amount: 10)

    assert_not transaction.valid?
    assert_includes transaction.errors[:type], "can't be blank"
  end

  # -- debitor_is_us? (from Accountable) --------------------------------------

  test "debitor_is_us? returns true when debitor has a family owner" do
    assert transactions(:debit_grocery).debitor_is_us?
  end

  test "debitor_is_us? returns false when debitor has no owner" do
    assert_not transactions(:credit_salary).debitor_is_us?
  end

  test "debitor_is_us? returns false when debitor is nil" do
    assert_not Transaction.new.debitor_is_us?
  end

  # -- creditor_is_us? (from Accountable) -------------------------------------

  test "creditor_is_us? returns true when creditor has a family owner" do
    assert transactions(:credit_salary).creditor_is_us?
  end

  test "creditor_is_us? returns false when creditor has no owner" do
    assert_not transactions(:debit_grocery).creditor_is_us?
  end

  # -- determine_debit_credit_or_transfer_type callback -----------------------

  test "sets Transfer when both debitor and creditor are ours" do
    transaction = Transaction.new(
      debitor: accounts(:checking),
      creditor: accounts(:savings),
      amount: 100
    )
    transaction.valid?

    assert_equal "Transfer", transaction.type
  end

  test "sets Credit when only creditor is ours" do
    transaction = Transaction.new(
      debitor: accounts(:employer),
      creditor: accounts(:checking),
      amount: 100
    )
    transaction.valid?

    assert_equal "Credit", transaction.type
  end

  test "sets Debit when only debitor is ours" do
    transaction = Transaction.new(
      debitor: accounts(:checking),
      creditor: accounts(:albert_heijn),
      amount: 100
    )
    transaction.valid?

    assert_equal "Debit", transaction.type
  end

  test "does not override type when already present" do
    transaction = Transaction.new(
      type: "Credit",
      debitor: accounts(:checking),
      creditor: accounts(:savings),
      amount: 100
    )
    transaction.valid?

    assert_equal "Credit", transaction.type
  end

  # -- type_icon --------------------------------------------------------------

  test "type_icon returns credit icon for Credit" do
    assert_equal "\u2B07\uFE0F \u{1F7E5}", transactions(:credit_salary).type_icon
  end

  test "type_icon returns debit icon for Debit" do
    assert_equal "\u2B06\uFE0F \u{1F7E9}", transactions(:debit_grocery).type_icon
  end

  test "type_icon returns transfer icon for Transfer" do
    assert_equal "\u{1F504} \u25FB\uFE0F", transactions(:transfer_savings).type_icon
  end

  # -- filter scopes ----------------------------------------------------------

  class FilterScopes < ActiveSupport::TestCase
    test "by_type returns only transactions of that type" do
      results = Transaction.by_type("Credit")

      assert results.all? { |t| t.type == "Credit" }
      assert_includes results, transactions(:credit_salary)
      assert_not_includes results, transactions(:debit_grocery)
    end

    test "by_type with blank string returns all transactions" do
      assert_equal Transaction.count, Transaction.by_type("").count
    end

    test "by_type with nil returns all transactions" do
      assert_equal Transaction.count, Transaction.by_type(nil).count
    end

    test "by_category with 'none' returns only uncategorized transactions" do
      results = Transaction.by_category("none")

      assert results.all? { |t| t.category.nil? }
      assert_includes results, transactions(:uncategorized)
      assert_not_includes results, transactions(:debit_grocery)
    end

    test "by_category with an id returns transactions with that category" do
      category = categories(:supermarket)
      results = Transaction.by_category(category.id.to_s)

      assert_includes results, transactions(:debit_grocery)
      assert_not_includes results, transactions(:credit_salary)
    end

    test "by_category with blank string returns all transactions" do
      assert_equal Transaction.count, Transaction.by_category("").count
    end

    test "by_account returns transactions where account is debitor or creditor" do
      account = accounts(:checking)
      results = Transaction.by_account(account.id.to_s)

      assert results.all? { |t| t.debitor_account_id == account.id || t.creditor_account_id == account.id }
      assert_includes results, transactions(:debit_grocery)
      assert_includes results, transactions(:credit_salary)
    end

    test "by_account with blank string returns all transactions" do
      assert_equal Transaction.count, Transaction.by_account("").count
    end

    test "by_account with nil returns all transactions" do
      assert_equal Transaction.count, Transaction.by_account(nil).count
    end

    test "in_date_range with only from filters lower bound" do
      from = 2.days.ago.to_date.to_s
      results = Transaction.in_date_range(from, nil)

      assert results.all? { |t| t.interest_at >= 2.days.ago.beginning_of_day }
    end

    test "in_date_range with only to filters upper bound" do
      to = 2.days.ago.to_date.to_s
      results = Transaction.in_date_range(nil, to)

      assert results.all? { |t| t.interest_at <= 2.days.ago.end_of_day }
    end

    test "in_date_range with both bounds filters to range" do
      from = 5.days.ago.to_date.to_s
      to = 1.day.ago.to_date.to_s
      results = Transaction.in_date_range(from, to)

      assert results.all? { |t| t.interest_at >= 5.days.ago.beginning_of_day && t.interest_at <= 1.day.ago.end_of_day }
    end

    test "in_date_range with invalid from ignores lower bound" do
      results = Transaction.in_date_range("not-a-date", nil)

      assert_equal Transaction.count, results.count
    end

    test "in_date_range with invalid to ignores upper bound" do
      results = Transaction.in_date_range(nil, "not-a-date")

      assert_equal Transaction.count, results.count
    end
  end

  # -- consolidatable? --------------------------------------------------------

  class Consolidatable < ActiveSupport::TestCase
    test "returns true when category is nil" do
      assert transactions(:uncategorized).consolidatable?
    end

    test "returns false when category is present" do
      assert_not transactions(:debit_grocery).consolidatable?
    end
  end

  # -- default scope ----------------------------------------------------------

  test "default scope orders transactions by booked_at descending" do
    booked_dates = Transaction.all.map(&:booked_at)

    assert_equal booked_dates.sort.reverse, booked_dates
  end

  # -- associations -----------------------------------------------------------

  test "belongs_to debitor (optional)" do
    assert_instance_of Account, transactions(:debit_grocery).debitor
  end

  test "belongs_to creditor (optional)" do
    assert_instance_of Account, transactions(:debit_grocery).creditor
  end

  test "belongs_to category (optional)" do
    assert_instance_of Category, transactions(:debit_grocery).category
  end

  test "category can be nil" do
    assert_nil transactions(:uncategorized).category
  end

  test "has_many chattels" do
    assert_includes transactions(:debit_grocery).chattels, chattels(:one)
  end

  class WhenProofOfPurchaseAttached < ActiveSupport::TestCase
    fixtures :transactions, :accounts, :categories, :chattels

    test "proof_of_purchase can be attached and retrieved" do
      transaction = transactions(:debit_grocery)
      transaction.proof_of_purchase.attach(
        io: StringIO.new("pdf content"),
        filename: "receipt.pdf",
        content_type: "application/pdf"
      )

      assert transaction.proof_of_purchase.attached?
      assert_equal "receipt.pdf", transaction.proof_of_purchase.filename.to_s
    end

    test "proof_of_purchase must be a pdf" do
      transaction = transactions(:debit_grocery)
      transaction.proof_of_purchase.attach(
        io: StringIO.new("plain text"),
        filename: "receipt.txt",
        content_type: "text/plain"
      )

      assert_not transaction.valid?
      assert_includes transaction.errors[:proof_of_purchase], I18n.t("activerecord.errors.messages.must_be_pdf")
    end
  end

  # -- searchable_transfers (from Linkable) -----------------------------------

  class SearchableTransfers < TransactionTest
    setup do
      @transaction = transactions(:debit_grocery)
    end

    test "returns empty relation when no query or amount given" do
      assert_empty @transaction.searchable_transfers
    end

    test "returns matching unlinked transfers for a query" do
      results = @transaction.searchable_transfers(query: "savings")

      assert_includes results, transactions(:transfer_savings)
    end

    test "excludes transfers already linked to this transaction" do
      results = @transaction.searchable_transfers(query: "groceries")

      assert_not_includes results, transactions(:transfer_for_grocery)
    end

    test "filters by amount" do
      results = @transaction.searchable_transfers(amount: "500.00")

      assert_includes results, transactions(:transfer_savings)
    end

    test "returns empty relation when nothing matches" do
      assert_empty @transaction.searchable_transfers(query: "nonexistent")
    end
  end
end

class TransactionSplittableTest < ActiveSupport::TestCase
  test "uncategorized scope excludes fully allocated split transactions" do
    transaction = transactions(:uncategorized)
    transaction.transaction_splits.create!(amount: transaction.amount, category: categories(:supermarket))

    assert_not Transaction.uncategorized.exists?(transaction.id)
  end

  test "split? returns false when no splits exist" do
    assert_not transactions(:uncategorized).split?
  end

  test "split? returns true when splits exist" do
    assert transactions(:debit_grocery).split?
  end

  test "split_balance equals amount minus sum of split amounts" do
    transaction = transactions(:debit_grocery)
    expected = transaction.amount - transaction.transaction_splits.sum(:amount)

    assert_equal expected, transaction.split_balance
  end

  test "fully_split? returns true when split_balance is zero" do
    transaction = transactions(:debit_grocery)
    remaining = transaction.split_balance
    transaction.transaction_splits.create!(amount: remaining)

    assert transaction.fully_split?
  end

  test "fully_split? returns false when split_balance is not zero" do
    assert_not transactions(:debit_grocery).fully_split?
  end

  test "uncategorized_amount returns only the untracked uncategorized remainder" do
    assert_equal 10.00, transactions(:debit_grocery).uncategorized_amount
  end

  test "uncategorized_amount includes a nil-category remainder split" do
    transaction = transactions(:uncategorized)
    transaction.transaction_splits.create!(amount: 10.00, category: categories(:supermarket))
    transaction.ensure_remainder_split

    assert_equal 15.00, transaction.reload.uncategorized_amount
  end

  test "amount_for uses split rows including the remainder row" do
    transaction = transactions(:debit_grocery)
    transaction.ensure_remainder_split

    assert_equal 40.00, transaction.amount_for(category: categories(:supermarket))
  end

  class RemainderSplit < ActiveSupport::TestCase
    test "ensure_remainder_split creates remainder when splits exist" do
      transaction = transactions(:uncategorized)
      transaction.transaction_splits.create!(amount: 10.00, category: categories(:supermarket))

      transaction.ensure_remainder_split

      remainder = transaction.transaction_splits.find_by(remainder: true)
      assert remainder
      assert_equal 15.00, remainder.amount
      assert_nil remainder.category
    end

    test "ensure_remainder_split uses transaction category for remainder" do
      transaction = transactions(:debit_grocery)
      transaction.ensure_remainder_split

      remainder = transaction.transaction_splits.find_by(remainder: true)
      assert remainder
      assert_equal transaction.category, remainder.category
    end

    test "ensure_remainder_split updates existing remainder amount" do
      transaction = transactions(:uncategorized)
      transaction.transaction_splits.create!(amount: 10.00, category: categories(:supermarket))
      transaction.ensure_remainder_split

      transaction.transaction_splits.create!(amount: 5.00, category: categories(:bakery))
      transaction.ensure_remainder_split

      remainders = transaction.transaction_splits.where(remainder: true)
      assert_equal 1, remainders.count
      assert_equal 10.00, remainders.first.amount
    end

    test "ensure_remainder_split removes remainder when fully covered by explicit splits" do
      transaction = transactions(:uncategorized)
      transaction.transaction_splits.create!(amount: 25.00, category: categories(:supermarket))
      transaction.ensure_remainder_split

      remainders = transaction.transaction_splits.where(remainder: true)
      assert_equal 0, remainders.count
    end

    test "ensure_remainder_split removes remainder when no explicit splits exist" do
      transaction = transactions(:uncategorized)
      transaction.transaction_splits.create!(amount: 10.00, category: categories(:supermarket))
      transaction.ensure_remainder_split

      transaction.transaction_splits.where(remainder: false).destroy_all
      transaction.ensure_remainder_split

      assert_equal 0, transaction.transaction_splits.count
    end
  end
end
