# Shows the assistant which transactions still need a category
module Assistant
  class FindUncategorizedTransactions < Tool
    description "List the transactions that still need a category, including partly filed ones, newest first."
    annotations read_only_hint: true
    input_schema(
      properties: {
        limit: { type: "integer", description: "How many transactions to list at most (25 by default)" }
      }
    )

    DEFAULT_LIMIT = 25
    HIGHEST_LIMIT = 100

    def self.call(server_context:, limit: DEFAULT_LIMIT)
      transactions = Transaction.uncategorized
                                .includes(:debitor, :creditor)
                                .limit(limit.clamp(1, HIGHEST_LIMIT))

      return answer("Every transaction is filed under a category.") if transactions.empty?

      answer(transactions.map { |transaction| describe(transaction) }.join("\n"))
    end

    def self.describe(transaction)
      "#{transaction.id}: #{transaction.booked_at.to_date} #{transaction.amount} " \
        "from #{transaction.debitor&.name} to #{transaction.creditor&.name} - #{transaction.note}"
    end
    private_class_method :describe
  end
end
