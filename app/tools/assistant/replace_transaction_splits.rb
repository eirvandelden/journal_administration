# Lets an assistant swap all the parts of a payment for a new set in one step
module Assistant
  class ReplaceTransactionSplits < Tool
    description "Replace every part of a payment with the parts given, all or nothing. What the parts do not " \
      "cover stays in a remainder part. Refused while the payment, or one of its parts, is charged to an " \
      "appropriation."
    annotations destructive_hint: true
    input_schema(
      properties: {
        transaction_id: { type: "integer", description: "The number identifying the payment" },
        splits: {
          type: "array",
          description: "The new parts",
          items: {
            type: "object",
            properties: {
              amount: { type: "number", description: "The part's amount in euros, at most two decimals" },
              category_id: { type: "integer", description: "The category the part belongs to" },
              note: { type: "string", description: "A note to remember the part by" }
            },
            required: [ "amount" ]
          }
        }
      },
      required: [ "transaction_id", "splits" ]
    )

    # Has no route: the UI changes parts one at a time
    def self.call(transaction_id:, splits:, server_context:)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      parts = parts_from(splits)
      return parts if parts.is_a?(MCP::Tool::Response)
      return refusal(transaction) unless transaction.replace_splits(parts)

      answer("Replaced the parts of transaction ##{transaction.id}:\n#{parts_list(transaction)}")
    end

    def self.parts_from(splits)
      splits.each_with_object([]) do |split, parts|
        part = split.to_h.with_indifferent_access
        cents = cents_from(part[:amount])
        return problem(two_decimals) if cents.nil?

        category = Category.find_by(id: part[:category_id]) if part[:category_id]
        return problem("No category ##{part[:category_id]} exists.") if part[:category_id] && category.nil?

        parts << { amount: cents, category: category, note: part[:note] }
      end
    end
    private_class_method :parts_from
  end
end
