class CreateTransactionGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :transaction_groups do |t|
      t.integer :parent_id, null: false
      t.integer :related_id, null: false # will lead to belongs_to :transaction, which is a keyword
    end
  end
end
