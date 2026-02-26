class RenameAndRecreateTransactions < ActiveRecord::Migration[8.1]
  def up
    remove_chattel_transaction_foreign_key
    rename_table :transactions, :legacy_transactions
    create_replacement_transactions_table
    add_new_transaction_foreign_keys
  end

  def down
    remove_new_transaction_foreign_keys
    drop_table :transactions
    rename_table :legacy_transactions, :transactions
    add_foreign_key :chattels, :transactions, column: :purchase_transaction_id
  end

  private

  def remove_chattel_transaction_foreign_key
    remove_foreign_key :chattels, column: :purchase_transaction_id
  end

  def create_replacement_transactions_table
    create_transactions_table
    add_index :transactions, :category_id
  end

  def create_transactions_table
    create_table :transactions do |t|
      t.datetime :booked_at, precision: nil
      t.datetime :interest_at, precision: nil
      t.text :note
      t.text :original_note
      t.decimal :original_balance_after_mutation
      t.string :original_tag
      t.integer :category_id
      t.timestamps
    end
  end

  def add_new_transaction_foreign_keys
    add_foreign_key :transactions, :categories
    add_foreign_key :chattels, :transactions, column: :purchase_transaction_id
  end

  def remove_new_transaction_foreign_keys
    remove_foreign_key :chattels, column: :purchase_transaction_id
    remove_foreign_key :transactions, :categories
  end
end
