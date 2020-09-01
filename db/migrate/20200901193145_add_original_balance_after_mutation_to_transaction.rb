class AddOriginalBalanceAfterMutationToTransaction < ActiveRecord::Migration[6.0]
  def change
    add_column :transactions, :original_balance_after_mutation, :decimal
  end
end
