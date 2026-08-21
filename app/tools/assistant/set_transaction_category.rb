# Files a transaction under a category on the assistant's behalf
module Assistant
  class SetTransactionCategory < Tool
    description "File a transaction under a category. Both are named by the numbers the other tools report."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        transaction_id: { type: "integer", description: "The number identifying the transaction" },
        category_id: { type: "integer", description: "The number identifying the category to file it under" }
      },
      required: [ "transaction_id", "category_id" ]
    )

    def self.call(transaction_id:, category_id:, server_context:)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      category = Category.find_by(id: category_id)
      return problem("No category ##{category_id} exists.") if category.nil?

      return problem(transaction.errors.full_messages.to_sentence) unless transaction.update(category: category)

      answer("Filed transaction ##{transaction.id} under #{category.full_name}.")
    end
  end
end
