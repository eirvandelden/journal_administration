class AddThemeColumnsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :color_scheme, :integer, default: 0, null: false
    add_column :users, :light_theme, :integer, default: 1, null: false
    add_column :users, :dark_theme, :integer, default: 1, null: false
  end
end
