module Importing
  module ING
    # Imports a single transaction from an ING bank CSV row
    #
    # Parses CSV row data, resolves or creates the involved accounts,
    # builds a Transaction object with proper type/category determination,
    # and saves it to the database.
    class ImportJob < ApplicationJob
      queue_as :default

      # Processes a CSV row from ING bank export format
      #
      # Handles account resolution (finding or creating accounts by number or name),
      # transaction construction with automatic type determination, and persistence.
      #
      # @param csv_row [Array<String>] A row from the CSV file containing transaction data
      # @return [void]
      # @raise [ActiveRecord::RecordInvalid] If the transaction fails validation or save
      def perform(csv_row)
        row = Row.parse(csv_row)
        return unless row
        persist_transaction_for(row)
      end

      private

      def persist_transaction_for(row)
        our_account = Account.find_or_create_by(account_number: row.our_account_number)
        their_account = resolve_counterparty_for(row)
        transaction = nil
        our_account.with_lock { transaction = build_transaction(row, our_account, their_account) }
        transaction&.save!
      end

      def resolve_counterparty_for(row)
        Account.resolve_for_import(
          account_number: row.their_account_number,
          description: row.description,
          name: row.initiator_name
        )
      end

      def build_transaction(row, our_account, their_account)
        Transaction.build_from_import(
          row,
          our_account: our_account,
          their_account: their_account
        )
      end
    end
  end
end
