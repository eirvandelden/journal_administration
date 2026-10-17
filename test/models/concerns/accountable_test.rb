require "test_helper"

class AccountableTest < ActiveSupport::TestCase
  test "uses managed household ownership" do
    transaction = Transaction.new(debitor: accounts(:checking), creditor: accounts(:albert_heijn))

    assert_predicate transaction, :debitor_is_us?
    assert_not transaction.creditor_is_us?
  end

  test "debitor_is_us? returns true for family-owned debitor" do
    transaction = Transaction.new(debitor: accounts(:checking))

    assert_predicate transaction, :debitor_is_us?
  end

  test "debitor_is_us? returns false for external debitor" do
    transaction = Transaction.new(debitor: accounts(:albert_heijn))

    assert_not transaction.debitor_is_us?
  end

  test "creditor_is_us? returns true for family-owned creditor" do
    transaction = Transaction.new(creditor: accounts(:checking))

    assert_predicate transaction, :creditor_is_us?
  end

  test "creditor_is_us? returns false for external creditor" do
    transaction = Transaction.new(creditor: accounts(:albert_heijn))

    assert_not transaction.creditor_is_us?
  end

  test "both_accounts_are_ours? returns true when both are family" do
    transaction = Transaction.new(debitor: accounts(:checking), creditor: accounts(:savings))

    assert_predicate transaction, :both_accounts_are_ours?
  end

  test "both_accounts_are_ours? returns false when one is external" do
    transaction = Transaction.new(debitor: accounts(:checking), creditor: accounts(:albert_heijn))

    assert_not transaction.both_accounts_are_ours?
  end

  test "move_counterparty replaces the debitor or the creditor that was the old account, keeping the type" do
    provider = accounts(:adyen)
    payment = transactions(:kruidvat_through_adyen)
    refund = transactions(:refund_through_adyen)

    payment.move_counterparty(from: provider, to: accounts(:kruidvat))
    refund.move_counterparty(from: provider, to: accounts(:kruidvat))

    assert_equal [ accounts(:kruidvat), accounts(:checking), "Credit" ],
      [ payment.reload.debitor, payment.creditor, payment.type ]
    assert_equal [ accounts(:checking), accounts(:kruidvat), "Debit" ],
      [ refund.reload.debitor, refund.creditor, refund.type ]
  end

  test "move_counterparty gives the new default category when the old default was kept" do
    accounts(:kruidvat).update!(category: categories(:household))
    payment = transactions(:kruidvat_through_adyen)

    payment.move_counterparty(from: accounts(:adyen), to: accounts(:kruidvat))

    assert_equal categories(:household), payment.reload.category
  end

  test "move_counterparty gives the new default to an uncategorised transaction of an uncategorised provider" do
    accounts(:adyen).update!(category: nil)
    accounts(:kruidvat).update!(category: categories(:household))
    payment = transactions(:kruidvat_through_adyen)
    payment.update!(category: nil)

    payment.move_counterparty(from: accounts(:adyen), to: accounts(:kruidvat))

    assert_equal categories(:household), payment.reload.category
  end

  test "move_counterparty keeps any other category" do
    accounts(:kruidvat).update!(category: categories(:household))
    payment = transactions(:hand_categorised_through_adyen)

    payment.move_counterparty(from: accounts(:adyen), to: accounts(:kruidvat))

    assert_equal categories(:bakery), payment.reload.category
  end

  test "move_counterparty keeps a split transaction's category and splits" do
    accounts(:kruidvat).update!(category: categories(:household))
    payment = transactions(:kruidvat_through_adyen)
    payment.transaction_splits.create!(amount: 400, category: categories(:bakery))
    payment.ensure_remainder_split

    payment.move_counterparty(from: accounts(:adyen), to: accounts(:kruidvat))

    assert_equal categories(:gifts), payment.reload.category
    assert_equal [ [ 400, categories(:bakery) ] ],
      payment.explicit_transaction_splits.map { |split| [ split.amount, split.category ] }
    assert_equal categories(:gifts), payment.transaction_splits.find_by!(remainder: true).category
  end
end
