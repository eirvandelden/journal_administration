class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts do |t|
      t.index :id
      t.string :account_number
      t.string :name
      t.integer :owner
      t.belongs_to :category, null: true, foreign_key: true

      t.timestamps
    end
  end
end
