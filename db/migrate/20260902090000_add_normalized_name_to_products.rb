class AddNormalizedNameToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :normalized_name, :string
    Product.reset_column_information
    Product.find_each { |product| product.update_columns(normalized_name: product.name.strip.downcase) }
    change_column_null :products, :normalized_name, false
    add_index :products, :normalized_name, unique: true
    remove_index :products, "LOWER(name)"
  end

  def down
    add_index :products, "LOWER(name)", unique: true
    remove_column :products, :normalized_name
  end
end
