class CreateBudgetCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :budget_categories do |t|
      t.references :budget, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_check_constraint :budget_categories,
      "amount > 0",
      name: "check_budget_category_amount_positive"

    add_index :budget_categories, [ :budget_id, :category_id ], unique: true
  end
end
