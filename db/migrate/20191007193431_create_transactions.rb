class CreateTransactions < ActiveRecord::Migration[6.0]
  def change
    create_table :transactions do |t|
      t.index :id
      t.bigint :debitor_account_id, null: true, foreign_key: true
      t.bigint :creditor_account_id, null: true, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2
      t.datetime :booked_at
      t.datetime :interest_at
      t.belongs_to :category, null: true, foreign_key: true
      t.text :note
      t.string :type

      t.timestamps
    end
  end
end
