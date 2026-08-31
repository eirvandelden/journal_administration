class AddOrderNumberToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :order_number, :string
    add_index :receipts, :order_number, unique: true
  end
end
