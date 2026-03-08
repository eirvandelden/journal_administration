# Ensures a transfer can only cover one source transaction.
class MakeTransferIdUniqueOnTransactionLinks < ActiveRecord::Migration[8.1]
  def change
    remove_index :transaction_links, %i[source_transaction_id transfer_id]
    remove_index :transaction_links, :transfer_id
    add_index :transaction_links, :transfer_id, unique: true
  end
end
