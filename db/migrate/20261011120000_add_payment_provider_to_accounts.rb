class AddPaymentProviderToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :payment_provider, :boolean, default: false, null: false
  end
end
