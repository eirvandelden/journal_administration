require "test_helper"
require Rails.root.join("db/data/20191024213804_set_transactions_from_etienne_or_michelle_to_samen_as_transfer").to_s

class SetTransactionsFromEtienneOrMichelleToSamenAsTransferTest < ActiveSupport::TestCase
  test "up works with mutation schema and categorizes family transfers" do
    migration = SetTransactionsFromEtienneOrMichelleToSamenAsTransfer.new

    transaction = Transaction.new(booked_at: Time.current, interest_at: Time.current)
    transaction.mutations.build(account: accounts(:checking), amount: -42)
    transaction.mutations.build(account: accounts(:savings), amount: 42)
    transaction.save!

    assert_nothing_raised { migration.up }

    assert_equal categories(:transfer).id, transaction.reload.category_id
  end
end
