class AddPackedToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_column :receipts, :packed, :boolean, default: true, null: false
  end
end
