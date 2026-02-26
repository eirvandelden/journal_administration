class CreateMutations < ActiveRecord::Migration[8.1]
  def change
    create_table :mutations do |t|
      t.references :transaction, null: false, foreign_key: true
      t.references :account,     null: false, foreign_key: true
      t.decimal    :amount, precision: 10, scale: 2, null: false
      t.timestamps
    end
  end
end
