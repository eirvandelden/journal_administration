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
