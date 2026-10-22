class ResetZeroParentCategoryIds < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE categories SET parent_category_id = NULL WHERE parent_category_id = 0"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
