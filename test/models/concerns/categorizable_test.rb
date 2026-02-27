require "test_helper"

class CategorizableTest < ActiveSupport::TestCase
  test "assign_category_from_mutations assigns external account's category" do
    txn = Transaction.new(booked_at: Time.current)
    txn.mutations.build(account: accounts(:checking),    amount: -50)
    txn.mutations.build(account: accounts(:albert_heijn), amount:  50)

    txn.assign_category_from_mutations

    assert_equal accounts(:albert_heijn).category, txn.category
  end

  test "assign_category_from_mutations assigns Transfer category when both accounts are family-owned" do
    txn = Transaction.new(booked_at: Time.current)
    txn.mutations.build(account: accounts(:checking), amount: -100)
    txn.mutations.build(account: accounts(:savings),  amount:  100)

    txn.assign_category_from_mutations

    assert_equal categories(:transfer), txn.category
  end

  test "assign_category_from_mutations assigns nil when external account has no category" do
    txn = Transaction.new(booked_at: Time.current)
    txn.mutations.build(account: accounts(:checking), amount: -25)
    txn.mutations.build(account: accounts(:unknown),  amount:  25)

    txn.assign_category_from_mutations

    assert_nil txn.category
  end
end
