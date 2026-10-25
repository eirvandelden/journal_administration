# Lets an assistant change one part of a split payment
module Assistant
  class UpdateTransactionSplit < Tool
    description "Change a part's amount, category or note. The remainder part cannot be changed by hand; it is " \
      "rebuilt automatically."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        transaction_id: { type: "integer", description: "The number identifying the payment" },
        transaction_split_id: { type: "integer", description: "The number identifying the part" },
        amount: { type: "number", description: "The new amount in euros, at most two decimals" },
        category_id: { type: "integer", description: "The category to move the part to" },
        note: { type: "string", description: "The new note" }
      },
      required: [ "transaction_id", "transaction_split_id" ]
    )

    # Mirrors transaction_splits#update
    def self.call(transaction_id:, transaction_split_id:, server_context:, **changes)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      part = transaction.explicit_transaction_splits.find_by(id: transaction_split_id)
      return problem("Transaction ##{transaction_id} has no part ##{transaction_split_id} to change.") if part.nil?

      attributes = attributes_from(changes)
      return attributes if attributes.is_a?(MCP::Tool::Response)

      change(transaction, part, attributes)
    end

    def self.attributes_from(changes)
      attributes = changes.slice(:note)
      if changes.key?(:amount)
        cents = cents_from(changes[:amount])
        return problem(two_decimals) if cents.nil?

        attributes[:amount] = cents
      end
      return attributes unless changes.key?(:category_id)

      category = Category.find_by(id: changes[:category_id])
      category ? attributes.merge(category: category) : problem("No category ##{changes[:category_id]} exists.")
    end
    private_class_method :attributes_from

    def self.change(transaction, part, attributes)
      return refusal(part) unless part.update(attributes)

      transaction.ensure_remainder_split
      answer("Changed part ##{part.id}. Parts of transaction ##{transaction.id}:\n#{parts_list(transaction)}")
    end
    private_class_method :change
  end
end
