class CreateAccountAliases < ActiveRecord::Migration[8.0]
  def change
    create_table :account_aliases do |t|
      t.references :account, null: false, foreign_key: true
      t.string :pattern, null: false
      t.timestamps
    end

    add_index :account_aliases, [ :account_id, :pattern ], unique: true
  end
end
