class SetTransactionsFromEtienneOrMichelleToSamenAsTransfer < ActiveRecord::Migration[6.0]
  def up
    return if transfer_category_id.blank?

    if legacy_transactions_schema?
      mark_legacy_transfers
    else
      mark_mutation_transfers
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def transfer_category_id
    @transfer_category_id ||= Category.find_by(name: "Transfer")&.id
  end

  def legacy_transactions_schema?
    column_exists?(:transactions, :debitor_account_id) &&
      column_exists?(:transactions, :creditor_account_id) &&
      column_exists?(:transactions, :type)
  end

  def mark_legacy_transfers
    our_account_ids = Account.where.not(owner: nil).ids

    Transaction.where(
      debitor_account_id: our_account_ids,
      creditor_account_id: our_account_ids
    ).where.not(type: "Transfer").update_all(type: "Transfer", category_id: transfer_category_id)
  end

  def mark_mutation_transfers
    return unless table_exists?(:mutations)

    transfer_transaction_ids = Transaction.joins(mutations: :account)
                                          .group(:id)
                                          .having("COUNT(mutations.id) >= 2")
                                          .having("SUM(CASE WHEN accounts.owner IS NULL THEN 1 ELSE 0 END) = 0")

    Transaction.where(id: transfer_transaction_ids).update_all(category_id: transfer_category_id)
  end
end
