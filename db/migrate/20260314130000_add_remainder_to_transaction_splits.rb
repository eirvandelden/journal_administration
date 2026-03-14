class AddRemainderToTransactionSplits < ActiveRecord::Migration[8.1]
  def change
    add_column :transaction_splits, :remainder, :boolean, default: false, null: false
  end
end
