# Provides factory methods for creating transactions from CSV imports
#
# Builds transaction objects from CSV row data, with proper account assignment
# and automatic type/category determination.
module Importable
  extend ActiveSupport::Concern

  class_methods do
    # Creates a transaction from CSV import row data
    #
    # Sets up debitor/creditor accounts, populates transaction fields from row data,
    # determines transaction type automatically, and assigns category based on type.
    # Also updates the counterparty account name if not already set.
    #
    # @param row [Object] CSV row object with date, amount, description, note, etc.
    # @param our_account [Account] The family account involved in the transaction
    # @param their_account [Account] The external account or counterparty
    # @return [Transaction] A new (unsaved) transaction instance
    def build_from_import(row, our_account:, their_account:)
      transaction = new(
        amount: row.amount,
        booked_at: row.date,
        interest_at: row.date,
        note: row.note,
        original_note: row.description,
        original_balance_after_mutation: row.original_balance,
        original_tag: row.original_tag
      )

      if row.debit?
        transaction.creditor = our_account
        transaction.debitor = their_account
      else
        transaction.debitor = our_account
        transaction.creditor = their_account
      end

      transaction.type = "Transfer" if transaction.both_accounts_are_ours?
      transaction.type ||= row.debit? ? "Credit" : "Debit"
      transaction.assign_category_from_type

      their_account.update(name: row.initiator_name) if their_account&.name.blank?

      transaction
    end
  end
end
