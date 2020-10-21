class AddCategoryGroupToCategory < ActiveRecord::Migration[6.0]
  def change
    add_reference :categories, :category_group, null: true, foreign_key: true
  end
end
