# Lets an assistant remove one part of a split payment
module Assistant
  class DeleteTransactionSplit < Tool
    description "Remove a part of a split payment; what it covered falls back to the remainder part. A part " \
      "charged to an appropriation is refused, and the remainder part cannot be removed by hand."
    annotations destructive_hint: true
    input_schema(
      properties: {
        transaction_id: { type: "integer", description: "The number identifying the payment" },
        transaction_split_id: { type: "integer", description: "The number identifying the part" }
      },
      required: [ "transaction_id", "transaction_split_id" ]
    )

    # Mirrors transaction_splits#destroy
    def self.call(transaction_id:, transaction_split_id:, server_context:)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      part = transaction.explicit_transaction_splits.find_by(id: transaction_split_id)
      return problem("Transaction ##{transaction_id} has no part ##{transaction_split_id} to remove.") if part.nil?
      return problem(charged(part)) if part.appropriation

      part.destroy
      transaction.ensure_remainder_split
      answer("Removed part ##{part.id}.\n#{remaining(transaction)}")
    end

    def self.charged(part)
      "Part ##{part.id} is charged to #{part.appropriation}; remove that charge in the app first."
    end
    private_class_method :charged

    def self.remaining(transaction)
      return "Transaction ##{transaction.id} has no parts left." unless transaction.transaction_splits.exists?

      "Parts of transaction ##{transaction.id}:\n#{parts_list(transaction)}"
    end
    private_class_method :remaining
  end
end
