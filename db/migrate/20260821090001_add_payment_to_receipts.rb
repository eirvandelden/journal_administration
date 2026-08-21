class AddPaymentToReceipts < ActiveRecord::Migration[8.1]
  def change
    add_reference :receipts, :payment, foreign_key: { to_table: :transactions }, index: true
  end
end
