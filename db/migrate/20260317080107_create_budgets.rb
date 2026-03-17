class CreateBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :budgets do |t|
      t.datetime :starts_at, null: false
      t.datetime :ends_at

      t.timestamps
    end

    add_check_constraint :budgets,
      "ends_at IS NULL OR starts_at < ends_at",
      name: "check_budget_dates"
  end
end
