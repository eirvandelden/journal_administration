class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :brand
      t.references :product_type, foreign_key: true
      t.decimal :pack_amount, precision: 10, scale: 3
      t.integer :pack_unit

      t.timestamps
    end
  end
end
