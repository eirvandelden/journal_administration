class AddUniqueIndexToBudgetsStartsAt < ActiveRecord::Migration[8.1]
  def change
    add_index :budgets, :starts_at, unique: true
  end
end
