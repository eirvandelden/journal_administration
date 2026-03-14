class CreateTransactionSplits < ActiveRecord::Migration[8.0]
  def change
    create_table :transaction_splits do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :category, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :note
      t.timestamps
    end
  end
end
