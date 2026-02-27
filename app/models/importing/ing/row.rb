# ING import domain namespace.
module Importing
  # ING-specific import structures.
  module ING
    # Represents a single row from an ING bank semicolon-delimited CSV export
    #
    # Parses raw CSV data into a structured object with typed accessors and
    # convenience predicates for transaction direction.
    class Row
      attr_reader :date, :initiator_name, :our_account_number, :their_account_number,
                  :code, :direction, :amount, :mutation_kind, :description,
                  :original_balance, :original_tag

      # Parses a raw CSV row into a Row object
      #
      # @param csv_row [Array<String>] A row from the ING CSV export
      # @return [Row, nil] Parsed row, or nil if the row is a header row
      def self.parse(csv_row)
        return nil if csv_row[0] == "Datum"
        new(**parsed_attributes_from(csv_row))
      rescue ArgumentError, TypeError
        nil
      end

      def self.parsed_attributes_from(csv_row)
        account_and_note_attributes_from(csv_row).merge(
          date: DateTime.parse(csv_row[0]),
          amount: csv_row[6].delete(".").tr(",", ".").to_d
        )
      end

      def self.account_and_note_attributes_from(csv_row)
        account_attributes_from(csv_row).merge(note_attributes_from(csv_row))
      end

      def self.account_attributes_from(csv_row)
        {
          initiator_name: csv_row[1],
          our_account_number: csv_row[2],
          their_account_number: csv_row[3],
          code: csv_row[4],
          direction: csv_row[5]
        }
      end

      def self.note_attributes_from(csv_row)
        {
          mutation_kind: csv_row[7],
          description: csv_row[8],
          original_balance: csv_row[9],
          original_tag: csv_row[10]
        }
      end

      private_class_method :parsed_attributes_from
      private_class_method :account_and_note_attributes_from
      private_class_method :account_attributes_from
      private_class_method :note_attributes_from

      def initialize(date:, initiator_name:, our_account_number:, their_account_number:,
                     code:, direction:, amount:, mutation_kind:, description:,
                     original_balance:, original_tag:)
        @date = date
        @initiator_name = Account.normalize(initiator_name)
        assign_accounts(our_account_number, their_account_number)
        assign_mutation_fields(code, direction, amount, mutation_kind, description, original_balance, original_tag)
      end

      # Builds the transaction note from available fields, omitting blank values
      #
      # @return [String] Newline-joined non-blank fields from description, code, and mutation_kind
      def note
        [ description, code, mutation_kind ].compact_blank.join("\n")
      end

      # Returns true if this is a debit transaction (money leaving our account)
      #
      # @return [Boolean]
      def debit?
        direction == "Af"
      end

      # Returns true if this is a credit transaction (money entering our account)
      #
      # @return [Boolean]
      def credit?
        direction == "Bij"
      end

      private

      def assign_accounts(our_account_number, their_account_number)
        @our_account_number = our_account_number
        @their_account_number = their_account_number
      end

      def assign_mutation_fields(code, direction, amount, mutation_kind, description, original_balance, original_tag)
        @code = code
        @direction = direction
        @amount = amount
        @mutation_kind = mutation_kind
        @description = description
        @original_balance = original_balance
        @original_tag = original_tag
      end
    end
  end
end
