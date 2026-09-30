class CreateAppropriations < ActiveRecord::Migration[8.1]
  def change
    create_table :appropriations do |t|
      t.string :purpose, null: false
      t.string :recipient, null: false
      t.integer :budget_year, null: false
      t.decimal :amount, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_check_constraint :appropriations, "amount > 0", name: "check_appropriation_amount_positive"

    add_index :appropriations, "LOWER(purpose), LOWER(recipient), budget_year",
      unique: true, name: "index_appropriations_on_lower_purpose_recipient_and_year"
  end
end
