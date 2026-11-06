module Importing
  module ING
    # Represents a single row from an ING bank semicolon-delimited CSV export
    #
    # Parses raw CSV data into a structured object with typed accessors and
    # convenience predicates for transaction direction.
    class Row
      attr_reader :date #: DateTime
      attr_reader :initiator_name #: String
      attr_reader :our_account_number #: String
      attr_reader :their_account_number #: String
      attr_reader :code #: String?
      attr_reader :direction #: String
      attr_reader :amount #: Integer
      attr_reader :mutation_kind #: String?
      attr_reader :description #: String?
      attr_reader :original_balance #: String?
      attr_reader :original_tag #: String?

      # Parses a raw CSV row into a Row object
      #
      # The CSV row comes from the ING CSV export. Returns nil if the row is a header row.
      #
      #: (Array[String?] csv_row) -> Row?
      def self.parse(csv_row)
        return nil if csv_row[0] == "Datum"

        new(
          date: DateTime.parse(csv_row[0]),
          initiator_name: csv_row[1],
          our_account_number: csv_row[2],
          their_account_number: csv_row[3],
          code: csv_row[4],
          direction: csv_row[5],
          amount: parse_amount(csv_row[6]),
          mutation_kind: csv_row[7],
          description: csv_row[8],
          original_balance: csv_row[9],
          original_tag: csv_row[10]
        )
      end

      # Raises ArgumentError when the text is not an amount. The amount is in cents.
      #
      #: (String? text) -> Integer
      def self.parse_amount(text)
        Cents.parse(text) || raise(ArgumentError, "not an amount: #{text.inspect}")
      end
      private_class_method :parse_amount

      #: (date: DateTime, initiator_name: String, our_account_number: String, their_account_number: String,
      #   code: String?, direction: String, amount: Integer, mutation_kind: String?, description: String?,
      #   original_balance: String?, original_tag: String?) -> void
      def initialize(date:, initiator_name:, our_account_number:, their_account_number:,
                     code:, direction:, amount:, mutation_kind:, description:,
                     original_balance:, original_tag:)
        @date = date
        @initiator_name = Account.find_by_alias(initiator_name)&.name || initiator_name
        @our_account_number = our_account_number
        @their_account_number = their_account_number
        @code = code
        @direction = direction
        @amount = amount
        @mutation_kind = mutation_kind
        @description = description
        @original_balance = original_balance
        @original_tag = original_tag
      end

      # Builds the transaction note from available fields, omitting blank values
      #
      # Joins the non-blank fields from description, code, and mutation_kind with newlines
      #
      #: () -> String
      def note
        [ description, code, mutation_kind ].compact_blank.join("\n")
      end

      # Returns true if this is a debit transaction (money leaving our account)
      #
      #: () -> bool
      def debit?
        direction == "Af"
      end

      # Returns true if this is a credit transaction (money entering our account)
      #
      #: () -> bool
      def credit?
        direction == "Bij"
      end
    end
  end
end
