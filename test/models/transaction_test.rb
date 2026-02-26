require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  # -- associations -----------------------------------------------------------

  test "has many mutations" do
    assert_equal 2, transactions(:debit_grocery).mutations.count
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

  # -- validations ------------------------------------------------------------

  test "invalid without booked_at" do
    txn = Transaction.new(booked_at: nil)
    assert_not txn.valid?
    assert_includes txn.errors[:booked_at], "can't be blank"
  end

  test "valid when mutations sum to zero" do
    txn = build_balanced_transaction(amount: 100)
    assert txn.valid?
  end

  test "invalid when there are no mutations" do
    txn = Transaction.new(booked_at: Time.current)

    assert_not txn.valid?
    assert txn.errors[:mutations].any?
  end

  test "invalid when there is only one mutation" do
    txn = Transaction.new(booked_at: Time.current)
    txn.mutations.build(account: accounts(:checking), amount: 50)

    assert_not txn.valid?
    assert txn.errors[:mutations].any?
  end

  test "invalid when mutations do not sum to zero" do
    txn = Transaction.new(booked_at: Time.current)
    txn.mutations.build(account: accounts(:checking),     amount: 100)
    txn.mutations.build(account: accounts(:albert_heijn), amount:  10)

    assert_not txn.valid?
    assert txn.errors[:mutations].any?
  end

  # -- convenience accessors --------------------------------------------------

  test "creditor returns account with positive mutation amount" do
    assert_equal accounts(:albert_heijn), transactions(:debit_grocery).creditor
  end

  test "debitor returns account with negative mutation amount" do
    assert_equal accounts(:checking), transactions(:debit_grocery).debitor
  end

  test "amount returns sum of positive mutations" do
    assert_equal 50.0, transactions(:debit_grocery).amount
  end

  # -- type_icon --------------------------------------------------------------

  test "type_icon returns credit icon when family account receives money" do
    assert_equal "⬇️ 🟥", transactions(:credit_salary).type_icon
  end

  test "type_icon returns debit icon when family account sends money" do
    assert_equal "⬆️ 🟩", transactions(:debit_grocery).type_icon
  end

  test "type_icon returns transfer icon when both accounts are family-owned" do
    assert_equal "🔄 ◻️", transactions(:transfer_savings).type_icon
  end

  # -- ordering ---------------------------------------------------------------

  test "ordered scope orders transactions by booked_at descending" do
    booked_dates = Transaction.ordered.map(&:booked_at)
    assert_equal booked_dates.sort.reverse, booked_dates
  end

  # -- our_mutations ----------------------------------------------------------

  test "our_mutations returns only mutations for family-owned accounts" do
    txn = transactions(:debit_grocery)
    our = txn.our_mutations
    assert our.all? { |m| m.account.owner.present? }
    assert_equal 1, our.count
  end

  test "destroy is restricted when chattels exist" do
    txn = transactions(:debit_grocery)

    assert_no_difference "Transaction.count" do
      assert_not txn.destroy
    end

    assert_includes txn.errors[:base], "Cannot delete record because dependent chattels exist"
  end

  private

  def build_balanced_transaction(amount:)
    txn = Transaction.new(booked_at: Time.current)
    txn.mutations.build(account: accounts(:checking),     amount: -amount)
    txn.mutations.build(account: accounts(:albert_heijn), amount:  amount)
    txn
  end
end
