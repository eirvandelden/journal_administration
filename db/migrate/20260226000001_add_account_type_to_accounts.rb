class AddAccountTypeToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :account_type, :integer, comment: "Nil when account type is not classified yet"
  end
end
