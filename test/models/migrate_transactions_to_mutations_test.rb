require "test_helper"
require Rails.root.join("db/data/20260226000001_migrate_transactions_to_mutations").to_s

class MigrateTransactionsToMutationsTest < ActiveSupport::TestCase
  LegacyTransaction = Struct.new(
    :id,
    :debitor_account_id,
    :creditor_account_id,
    :amount,
    :booked_at,
    :interest_at,
    :note,
    :original_note,
    :original_balance_after_mutation,
    :original_tag,
    :category_id,
    :created_at,
    :updated_at,
    keyword_init: true
  )

  test "migrate_legacy_transaction persists transaction and mutations in one pass" do
    migration = MigrateTransactionsToMutations.new
    legacy_transaction = build_legacy_transaction

    assert_difference "Transaction.count", 1 do
      assert_difference "Mutation.count", 2 do
        migration.send(:migrate_legacy_transaction, legacy_transaction)
      end
    end

    transaction = Transaction.order(:id).last
    assert_equal 0, transaction.mutations.sum(:amount)
  end

  test "migrate_legacy_transaction clears chattel links for skipped legacy rows" do
    migration = MigrateTransactionsToMutations.new
    legacy_id = chattels(:one).purchase_transaction_id
    legacy_transaction = build_legacy_transaction(id: legacy_id, booked_at: nil)

    migration.send(:migrate_legacy_transaction, legacy_transaction)

    assert_nil chattels(:one).reload.purchase_transaction_id
  end

  test "up does not raise when legacy_transactions table is absent" do
    migration = MigrateTransactionsToMutations.new

    assert_nothing_raised { migration.up }
  end

  private

  def build_legacy_transaction(overrides = {})
    LegacyTransaction.new(**legacy_transaction_attributes.merge(overrides))
  end

  def legacy_transaction_attributes
    transfer_identifiers.merge(legacy_entry_fields).merge(legacy_audit_fields)
  end

  def transfer_identifiers
    {
      id: 999_999,
      debitor_account_id: accounts(:checking).id,
      creditor_account_id: accounts(:albert_heijn).id,
      category_id: categories(:supermarket).id
    }
  end

  def legacy_entry_fields
    {
      amount: 50,
      booked_at: Time.current,
      interest_at: Time.current,
      note: "Legacy migrated transaction",
      original_note: "Legacy original note",
      original_balance_after_mutation: 1000,
      original_tag: "legacy"
    }
  end

  def legacy_audit_fields
    timestamp = Time.current
    { created_at: timestamp, updated_at: timestamp }
  end
end
