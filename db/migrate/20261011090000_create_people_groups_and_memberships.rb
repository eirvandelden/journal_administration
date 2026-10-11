class CreatePeopleGroupsAndMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.boolean :household, default: false, null: false

      t.timestamps
    end
    add_index :people, "LOWER(name)", unique: true, name: "index_people_on_lower_name"

    create_table :groups do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :groups, "LOWER(name)", unique: true, name: "index_groups_on_lower_name"

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: { on_delete: :restrict }
      t.references :person, null: false, foreign_key: { on_delete: :restrict }

      t.timestamps
    end
    add_index :group_memberships, [ :group_id, :person_id ], unique: true

    add_reference :accounts, :person, foreign_key: { on_delete: :restrict }
    add_reference :accounts, :group, foreign_key: { on_delete: :restrict }
    add_check_constraint :accounts, "person_id IS NULL OR group_id IS NULL",
      name: "accounts_have_at_most_one_managed_owner"

    add_reference :appropriations, :person, foreign_key: { on_delete: :restrict }
    remove_index :appropriations, name: "index_appropriations_on_lower_purpose_recipient_and_year"
    add_index :appropriations, "LOWER(purpose), person_id, budget_year", unique: true,
      where: "person_id IS NOT NULL", name: "index_appropriations_on_person_and_purpose_and_year"
  end
end
