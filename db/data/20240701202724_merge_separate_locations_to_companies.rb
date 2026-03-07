# frozen_string_literal: true

class MergeSeparateLocationsToCompanies < ActiveRecord::Migration[7.1]
  def up
    merge_accounts(
      matcher: /AH to go|AH |.*(Albert Heijn|ALBERT HEIJN|AH to go)/,
      target_name: "Albert Heijn B.V."
    )
    merge_accounts(matcher: /Jumbo /, target_name: "Jumbo B.V.")
    merge_accounts(matcher: /.*(Kruidvat|KRUIDVAT)/, target_name: "Kruidvat B.V.")
  end

  def down
    # raise ActiveRecord::IrreversibleMigration
  end

  private

  def merge_accounts(matcher:, target_name:)
    target_account = Account.find_or_create_by(name: target_name)
    source_accounts = Account.all.select { |account| account.name.to_s.match?(matcher) }

    source_accounts.each { |source_account| repoint_references(source_account:, target_account:) }
    (source_accounts - [ target_account ]).each(&:destroy)
  end

  def repoint_references(source_account:, target_account:)
    return if source_account.id == target_account.id

    if legacy_transactions_schema?
      Transaction.where(debitor_account_id: source_account.id).update_all(debitor_account_id: target_account.id)
      Transaction.where(creditor_account_id: source_account.id).update_all(creditor_account_id: target_account.id)
      return
    end

    return unless mutations_schema?

    Mutation.where(account_id: source_account.id).update_all(account_id: target_account.id)
  end

  def legacy_transactions_schema?
    column_exists?(:transactions, :debitor_account_id) &&
      column_exists?(:transactions, :creditor_account_id)
  end

  def mutations_schema?
    table_exists?(:mutations) && column_exists?(:mutations, :account_id)
  end
end
