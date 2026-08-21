class AddAssistantTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :assistant_token, :string
    add_index :users, :assistant_token, unique: true
  end
end
