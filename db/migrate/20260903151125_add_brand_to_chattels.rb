class AddBrandToChattels < ActiveRecord::Migration[8.1]
  def change
    add_column :chattels, :brand, :string
  end
end
