class AddAppropriationToTransactionsAndSplits < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :appropriation, foreign_key: true
    add_reference :transaction_splits, :appropriation, foreign_key: true
  end
end
