# Lets an assistant delete a transaction
module Assistant
  class DeleteTransaction < Tool
    description "Delete a transaction together with its parts and their charges. Refused while a chattel " \
      "was bought with it."
    annotations destructive_hint: true
    input_schema(
      properties: { transaction_id: { type: "integer", description: "The number identifying the transaction" } },
      required: [ "transaction_id" ]
    )

    # Mirrors transactions#destroy
    def self.call(transaction_id:, server_context:)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?
      return refusal(transaction) unless transaction.destroy

      answer("Deleted transaction ##{transaction_id}.")
    rescue ActiveRecord::InvalidForeignKey
      problem("Transaction ##{transaction_id} cannot be deleted: #{bought_with(transaction)} was bought with it.")
    end

    def self.bought_with(transaction)
      transaction.chattels.reload.map { |chattel| "chattel ##{chattel.id} #{chattel.name}" }.to_sentence
    end
    private_class_method :bought_with
  end
end
