class CreateReceipts < ActiveRecord::Migration[8.1]
  def change
    create_table :receipts do |t|
      t.references :shop, null: false, foreign_key: { to_table: :accounts }
      t.date :issued_on, null: false
      t.decimal :total_amount, precision: 10, scale: 2, null: false

      t.timestamps
    end

    create_table :receipt_lines do |t|
      t.references :receipt, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.decimal :quantity, precision: 10, scale: 3, null: false
      t.decimal :pack_amount, precision: 10, scale: 3
      t.integer :pack_unit
      t.decimal :full_amount, precision: 10, scale: 2, null: false
      t.decimal :discount_amount, precision: 10, scale: 2, default: "0.0", null: false
      t.decimal :paid_amount, precision: 10, scale: 2, null: false

      t.timestamps
    end
  end
end
