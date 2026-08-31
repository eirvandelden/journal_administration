class AddUniqueIndexToProductsName < ActiveRecord::Migration[8.1]
  def change
    add_index :products, "LOWER(name)", unique: true
  end
end
