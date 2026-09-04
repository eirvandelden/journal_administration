class RemovePackSizeFromProductsAndReceiptLines < ActiveRecord::Migration[8.1]
  def change
    remove_column :products, :pack_amount, :decimal, precision: 10, scale: 3
    remove_column :products, :pack_unit, :integer
    remove_column :receipt_lines, :pack_amount, :decimal, precision: 10, scale: 3
    remove_column :receipt_lines, :pack_unit, :integer
  end
end
