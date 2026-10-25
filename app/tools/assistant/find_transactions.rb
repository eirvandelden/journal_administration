# Lets an assistant look through the transactions the way the transactions page does
module Assistant
  class FindTransactions < Tool
    DEFAULT_LIMIT = 25
    HIGHEST_LIMIT = 100

    description "List transactions, newest first, narrowed by type, category, account, period or a search " \
      "for note and amount. Mirrors the transactions page."
    annotations read_only_hint: true
    input_schema(
      properties: {
        type: { type: "string", enum: Transaction::TYPES, description: "Only this kind of transaction" },
        category_id: { type: "integer", description: "Only transactions filed under this category" },
        account_id: { type: "integer", description: "Only transactions to or from this account" },
        start_date: { type: "string", description: "First interest day, written as 2026-08-01" },
        end_date: { type: "string", description: "Last interest day, written as 2026-08-31" },
        uncategorized: { type: "boolean", description: "Only transactions that still need a category" },
        query: { type: "string", description: "Part of the note, or of the amount in euros" },
        limit: { type: "integer", description: "How many to list at most (#{DEFAULT_LIMIT} by default, " \
          "#{HIGHEST_LIMIT} at the very most)" }
      }
    )

    # Mirrors transactions#index
    def self.call(server_context:, limit: DEFAULT_LIMIT, uncategorized: false, query: nil, start_date: nil,
      end_date: nil, **filters)
      first_day, last_day = start_date.presence && day(start_date), end_date.presence && day(end_date)
      return problem("Write days as 2026-08-01.") if unreadable?(start_date, first_day, end_date, last_day)
      return problem(backwards(first_day, last_day)) if first_day && last_day && last_day < first_day

      matches = narrowed(filters, query, uncategorized, start_date && first_day, end_date && last_day)
      return answer("No transaction matches.") if matches.empty?

      shown = matches.limit(limit.clamp(1, HIGHEST_LIMIT)).to_a
      answer([ *shown.map { |transaction| describe(transaction) }, held_back(matches, shown) ].compact.join("\n"))
    end

    def self.unreadable?(start_date, first_day, end_date, last_day)
      (start_date.present? && first_day.nil?) || (end_date.present? && last_day.nil?)
    end
    private_class_method :unreadable?

    def self.narrowed(filters, query, uncategorized, first_day, last_day)
      matches = query.present? ? Transaction.search(query).unscope(:limit) : Transaction.all
      matches = matches.by_type(filters[:type]).by_category(filters[:category_id]&.to_s)
                       .by_account(filters[:account_id]).in_date_range(first_day, last_day)
      matches = matches.uncategorized if uncategorized
      matches.includes(:debitor, :creditor, :category)
    end
    private_class_method :narrowed

    def self.describe(transaction)
      "#{transaction.id}: #{transaction.type} #{transaction.booked_at.to_date} #{euros(transaction.amount)} " \
        "from #{transaction.debitor&.name} to #{transaction.creditor&.name}, " \
        "#{transaction.category&.full_name || 'no category'} - #{transaction.note}"
    end
    private_class_method :describe

    def self.held_back(matches, shown)
      total = matches.count
      return nil if total <= shown.length

      "Showing #{shown.length} of #{total} transactions - narrow the search to see the rest."
    end
    private_class_method :held_back
  end
end
