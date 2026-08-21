class CreateProductTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :product_types do |t|
      t.string :name, null: false
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end
    add_index :product_types, "LOWER(name)", unique: true
  end
end
