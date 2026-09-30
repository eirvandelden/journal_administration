# Lets an assistant charge a payment, or one part of a split payment, to an appropriation
module Assistant
  class ChargeToAppropriation < Tool
    description "Charge a payment to an appropriation, moving any earlier charge. A split payment is charged " \
      "per part: name the part with transaction_split_id. Transfers cannot be charged. Charging does not " \
      "change the payment's category."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        appropriation_id: { type: "integer", description: "The number identifying the appropriation" },
        transaction_id: { type: "integer", description: "The number identifying the payment" },
        transaction_split_id: { type: "integer", description: "The number identifying one part of a split payment" }
      },
      required: [ "appropriation_id", "transaction_id" ]
    )

    # @return [MCP::Tool::Response]
    def self.call(appropriation_id:, transaction_id:, server_context:, transaction_split_id: nil)
      appropriation = Appropriation.find_by(id: appropriation_id)
      return problem("No appropriation ##{appropriation_id} exists.") if appropriation.nil?

      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      chargeable = chargeable_in(transaction, transaction_split_id)
      return chargeable if chargeable.is_a?(MCP::Tool::Response)

      charge(chargeable, appropriation)
    end

    # The payment itself, or the named part of it; a refusal when neither can be charged as asked
    def self.chargeable_in(transaction, transaction_split_id)
      return part_of(transaction, transaction_split_id) if transaction_split_id
      return problem(name_a_part(transaction)) if transaction.split?

      transaction
    end
    private_class_method :chargeable_in

    # The named part, only among the payment's own parts
    def self.part_of(transaction, transaction_split_id)
      transaction.transaction_splits.find_by(id: transaction_split_id) ||
        problem("Transaction ##{transaction.id} has no part ##{transaction_split_id}.")
    end
    private_class_method :part_of

    # Lists the explicit parts, so the assistant can charge each one
    def self.name_a_part(transaction)
      parts = transaction.explicit_transaction_splits.map do |part|
        "#{part.id}: #{format("%.2f", part.amount)} #{part.category&.name} #{part.note}".strip
      end
      "Transaction ##{transaction.id} is split, so charge its parts instead, naming one as " \
        "transaction_split_id:\n#{parts.join("\n")}"
    end
    private_class_method :name_a_part

    # Saves the charge, or passes on why the books refuse it
    def self.charge(chargeable, appropriation)
      return problem(chargeable.errors.full_messages.to_sentence) unless chargeable.update(appropriation:)

      answer("Charged #{format("%.2f", chargeable.amount)} to #{appropriation}.")
    end
    private_class_method :charge
  end
end
