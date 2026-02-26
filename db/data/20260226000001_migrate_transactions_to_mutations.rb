class MigrateTransactionsToMutations < ActiveRecord::Migration[8.1]
  # Temporary model pointing to the old transactions data
  class LegacyTransaction < ApplicationRecord
    self.table_name = "legacy_transactions"
    self.inheritance_column = :_type_disabled
  end

  def up
    ActiveRecord::Base.transaction do
      LegacyTransaction.find_each { |legacy_transaction| migrate_legacy_transaction(legacy_transaction) }
    end

    # Set account_type for family-owned accounts
    Account.where.not(owner: nil).update_all(account_type: Account.account_types[:asset])
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def migrate_legacy_transaction(legacy_transaction)
    return log_skipped_transaction(legacy_transaction) if invalid_legacy_transaction?(legacy_transaction)

    transaction = create_transaction_from(legacy_transaction)
    create_mutations_for(transaction, legacy_transaction)
    repoint_chattels(legacy_transaction, transaction)
  end

  def log_skipped_transaction(legacy_transaction)
    Rails.logger.warn("Skipping legacy transaction #{legacy_transaction.id}: missing required bookkeeping fields")
  end

  def create_transaction_from(legacy_transaction)
    Transaction.create!(transaction_attributes_for(legacy_transaction))
  end

  def create_mutations_for(transaction, legacy_transaction)
    # Debitor account: money leaves → negative amount
    transaction.mutations.create!(account_id: legacy_transaction.debitor_account_id, amount: -legacy_transaction.amount)
    # Creditor account: money arrives → positive amount
    transaction.mutations.create!(account_id: legacy_transaction.creditor_account_id, amount: legacy_transaction.amount)
  end

  def repoint_chattels(legacy_transaction, transaction)
    Chattel.where(purchase_transaction_id: legacy_transaction.id).update_all(purchase_transaction_id: transaction.id)
  end

  def transaction_attributes_for(legacy_transaction)
    base_transaction_attributes_for(legacy_transaction).merge(
      created_at: legacy_transaction.created_at,
      updated_at: legacy_transaction.updated_at
    )
  end

  def invalid_legacy_transaction?(legacy_transaction)
    legacy_transaction.debitor_account_id.blank? ||
      legacy_transaction.creditor_account_id.blank? ||
      legacy_transaction.amount.blank?
  end

  def base_transaction_attributes_for(legacy_transaction)
    {
      booked_at: legacy_transaction.booked_at,
      interest_at: legacy_transaction.interest_at,
      note: legacy_transaction.note,
      original_note: legacy_transaction.original_note,
      original_balance_after_mutation: legacy_transaction.original_balance_after_mutation,
      original_tag: legacy_transaction.original_tag,
      category_id: legacy_transaction.category_id
    }
  end
end
