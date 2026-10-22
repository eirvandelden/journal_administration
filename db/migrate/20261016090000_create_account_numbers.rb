class CreateAccountNumbers < ActiveRecord::Migration[8.1]
  def change
    create_table :account_numbers do |t|
      t.references :account, null: false, foreign_key: true
      t.string :number, null: false

      t.timestamps
    end

    add_index :account_numbers, :number, unique: true
  end
end
