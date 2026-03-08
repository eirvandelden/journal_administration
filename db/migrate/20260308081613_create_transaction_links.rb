# Creates join table linking source transactions to their covering transfers
class CreateTransactionLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_links do |t|
      t.references :source_transaction, null: false, foreign_key: { to_table: :transactions }
      t.references :transfer, null: false, foreign_key: { to_table: :transactions }

      t.timestamps
    end

    add_index :transaction_links, %i[source_transaction_id transfer_id], unique: true
  end
end
