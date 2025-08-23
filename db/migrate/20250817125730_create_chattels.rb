class CreateChattels < ActiveRecord::Migration[7.2]
  def change
    create_table :chattels do |t|
      t.string :name, null: false
      t.string :kind
      t.string :model_number
      t.string :serial_number
      t.belongs_to :purchase_transaction, null: true, foreign_key: { to_table: :transactions }
      t.datetime :purchased_at
      t.datetime :warranty_expires_at
      t.datetime :left_possession_at
      t.decimal :purchase_price, precision: 10, scale: 2
      t.text :notes

      t.timestamps
    end
  end
end
