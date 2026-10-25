# Lets an assistant correct a transaction's amount, days, category or note
module Assistant
  class UpdateTransaction < Tool
    description "Change a transaction's amount, booking day, interest day, category or note. Leave out what " \
      "stays. Its accounts and type stay as they are."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        transaction_id: { type: "integer", description: "The number identifying the transaction" },
        amount: { type: "number", description: "The new amount in euros, at most two decimals" },
        booked_on: { type: "string", description: "The new booking day, written as 2026-08-01" },
        interest_on: { type: "string", description: "The new interest day, written as 2026-08-01" },
        category_id: { type: "integer", description: "The category to file it under" },
        note: { type: "string", description: "The new note" }
      },
      required: [ "transaction_id" ]
    )

    # Mirrors transactions#update
    def self.call(transaction_id:, server_context:, **changes)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      attributes = attributes_from(changes)
      return attributes if attributes.is_a?(MCP::Tool::Response)
      return refusal(transaction) unless transaction.update(attributes)

      answer("Updated transaction ##{transaction.id}.")
    end

    def self.attributes_from(changes)
      problem_found = [ amount_in(changes), days_in(changes), category_in(changes) ]
      problem_found.find { |found| found.is_a?(MCP::Tool::Response) } ||
        problem_found.reduce(changes.slice(:note), :merge)
    end
    private_class_method :attributes_from

    def self.amount_in(changes)
      return {} unless changes.key?(:amount)

      cents = cents_from(changes[:amount])
      cents ? { amount: cents } : problem(two_decimals)
    end
    private_class_method :amount_in

    def self.days_in(changes)
      { booked_at: :booked_on, interest_at: :interest_on }.each_with_object({}) do |(column, name), found|
        next unless changes.key?(name)

        read = day(changes[name])
        return problem("Write days as 2026-08-01.") if read.nil?

        found[column] = read.beginning_of_day
      end
    end
    private_class_method :days_in

    def self.category_in(changes)
      return {} unless changes.key?(:category_id)

      category = Category.find_by(id: changes[:category_id])
      category ? { category: category } : problem("No category ##{changes[:category_id]} exists.")
    end
    private_class_method :category_in
  end
end
