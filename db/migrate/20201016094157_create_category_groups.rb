class CreateCategoryGroups < ActiveRecord::Migration[6.0]
  def change
    create_table :category_groups do |t|
      t.string :name
      t.belongs_to :account, null: true, foreign_key: true

      t.timestamps
    end
  end
end
