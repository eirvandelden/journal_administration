class SetTransactionsFromEtienneOrMichelleToSamenAsTransfer < ActiveRecord::Migration[6.0]
  def up
    our_account_ids = Account.where.not(owner: nil).ids
    category_id     = Category.find_by(name: "Transfer").id
    Transaction.where(debitor_account_id: our_account_ids, creditor_account_id: our_account_ids).where.not(type: "Transfer").update_all(type: "Transfer", category_id: category_id)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
