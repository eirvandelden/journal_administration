class AddUnicodeNameKeys < ActiveRecord::Migration[8.1]
  def change
    add_column :people, :name_key, :string
    remove_index :people, name: "index_people_on_lower_name"
    add_index :people, :name_key, unique: true

    add_column :groups, :name_key, :string
    remove_index :groups, name: "index_groups_on_lower_name"
    add_index :groups, :name_key, unique: true
  end
end
