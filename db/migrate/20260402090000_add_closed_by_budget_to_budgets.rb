class AddClosedByBudgetToBudgets < ActiveRecord::Migration[8.1]
  def change
    add_reference :budgets,
      :closed_by_budget,
      foreign_key: { to_table: :budgets, on_delete: :nullify },
      index: true
  end
end
