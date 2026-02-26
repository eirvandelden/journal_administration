module Importable
  extend ActiveSupport::Concern

  class_methods do
    # Creates a Transaction with two Mutations from CSV import row data.
    #
    # Returns nil (without saving) when the import would create a duplicate:
    # transfers between family accounts can appear in both account exports, so
    # we check for an existing Mutation with the same account, signed amount,
    # and booked_at before building.
    #
    # @param row [Object] CSV row object with date, amount, description, etc.
    # @param our_account [Account] The family account involved in the transaction
    # @param their_account [Account] The external or counterparty account
    # @return [Transaction, nil] A new (unsaved) transaction, or nil if duplicate
    def build_from_import(row, our_account:, their_account:)
      update_counterparty_name(their_account, row)
      our_amount, their_amount = mutation_amounts_for(row)
      return nil if duplicate_family_transfer?(row, our_account, their_account, our_amount)
      build_transaction(row, our_account, their_account, our_amount, their_amount)
    end

    private

    def update_counterparty_name(their_account, row)
      their_account&.update(name: row.initiator_name) if their_account&.name.blank?
    end

    def mutation_amounts_for(row)
      return [ -row.amount, row.amount ] if row.debit?

      [ row.amount, -row.amount ]
    end

    def duplicate_family_transfer?(row, our_account, their_account, our_amount)
      return false unless their_account&.owner.present?

      Mutation.joins(:journal_entry)
              .where(account: our_account, amount: our_amount)
              .where(transactions: { booked_at: row.date })
              .exists?
    end

    def build_transaction(row, our_account, their_account, our_amount, their_amount)
      txn = new(transaction_attributes_from(row))
      txn.mutations.build(account: our_account, amount: our_amount)
      txn.mutations.build(account: their_account, amount: their_amount)
      txn.assign_category_from_mutations
      txn
    end

    def transaction_attributes_from(row)
      {
        booked_at: row.date,
        interest_at: row.date,
        note: row.note,
        original_note: row.description,
        original_balance_after_mutation: row.original_balance,
        original_tag: row.original_tag
      }
    end
  end
end
