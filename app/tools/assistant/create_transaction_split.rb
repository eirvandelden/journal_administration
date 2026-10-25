# Lets an assistant carve a part out of a payment for a category
module Assistant
  class CreateTransactionSplit < Tool
    description "Add one part to a payment: an amount for a category. What no part covers stays in a remainder " \
      "part that is rebuilt automatically. A part cannot exceed what is left, and a transfer has no parts."
    input_schema(
      properties: {
        transaction_id: { type: "integer", description: "The number identifying the payment" },
        amount: { type: "number", description: "The part's amount in euros, at most two decimals" },
        category_id: { type: "integer", description: "The category the part belongs to" },
        note: { type: "string", description: "A note to remember the part by" }
      },
      required: [ "transaction_id", "amount" ]
    )

    # Mirrors transaction_splits#create
    def self.call(transaction_id:, amount:, server_context:, category_id: nil, note: nil)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      cents = cents_from(amount)
      return problem(two_decimals) if cents.nil?

      category = Category.find_by(id: category_id) if category_id
      return problem("No category ##{category_id} exists.") if category_id && category.nil?

      add(transaction, transaction.transaction_splits.build(amount: cents, category: category, note: note))
    end

    def self.add(transaction, part)
      return refusal(part) unless part.save

      transaction.ensure_remainder_split
      answer("Added part ##{part.id}. Parts of transaction ##{transaction.id}:\n#{parts_list(transaction)}")
    end
    private_class_method :add
  end
end
