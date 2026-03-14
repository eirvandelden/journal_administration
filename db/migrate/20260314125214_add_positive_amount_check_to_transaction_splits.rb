class AddPositiveAmountCheckToTransactionSplits < ActiveRecord::Migration[8.0]
  def change
    add_check_constraint :transaction_splits, "amount > 0", name: "transaction_splits_amount_positive"
  end
end
