module Importing
  module ING
    class Row
      attr_reader :date, :initiator_name, :our_account_number, :their_account_number,
                  :code, :direction, :amount, :mutation_kind, :description,
                  :original_balance, :original_tag

      def self.parse(csv_row)
        return nil if csv_row[0] == "Datum"

        new(
          date: DateTime.parse(csv_row[0]),
          initiator_name: csv_row[1],
          our_account_number: csv_row[2],
          their_account_number: csv_row[3],
          code: csv_row[4],
          direction: csv_row[5],
          amount: csv_row[6].delete(".").tr(",", ".").to_d,
          mutation_kind: csv_row[7],
          description: csv_row[8],
          original_balance: csv_row[9],
          original_tag: csv_row[10]
        )
      end

      def initialize(date:, initiator_name:, our_account_number:, their_account_number:,
                     code:, direction:, amount:, mutation_kind:, description:,
                     original_balance:, original_tag:)
        @date = date
        @initiator_name = Account.normalize(initiator_name)
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

      def note
        "#{description}\n#{code}\n#{mutation_kind}"
      end

      def debit?
        direction == "Af"
      end

      def credit?
        direction == "Bij"
      end
    end
  end
end
