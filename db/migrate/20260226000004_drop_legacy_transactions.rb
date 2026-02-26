class DropLegacyTransactions < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:legacy_transactions)
    return if table_exists?(:legacy_transactions_backup)

    rename_table :legacy_transactions, :legacy_transactions_backup
  end

  def down
    return unless table_exists?(:legacy_transactions_backup)

    rename_table :legacy_transactions_backup, :legacy_transactions
  end
end
