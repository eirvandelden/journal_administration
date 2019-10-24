class AddDirectionToCategory < ActiveRecord::Migration[6.0]
  def change
    add_column :categories, :direction, :integer
  end
end
