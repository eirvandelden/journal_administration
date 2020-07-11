class AddPrimaryCategoryToCategories < ActiveRecord::Migration[6.0]
  def change
    add_reference :categories, :parent_category, null: true, index: true
  end
end
