# Shows an assistant everything it may act on next for one transaction
module Assistant
  class ShowTransaction < Tool
    description "Show one transaction with its category, its parts (with the numbers to name them by), " \
      "any charge to an appropriation, the receipt it paid and the chattels bought with it."
    annotations read_only_hint: true
    input_schema(
      properties: { transaction_id: { type: "integer", description: "The number identifying the transaction" } },
      required: [ "transaction_id" ]
    )

    # Mirrors transactions#show
    def self.call(transaction_id:, server_context:)
      transaction = Transaction.find_by(id: transaction_id)
      return problem("No transaction ##{transaction_id} exists.") if transaction.nil?

      sections = [ summary(transaction), parts(transaction), receipt(transaction), chattels(transaction) ]
      answer(sections.compact.join("\n"))
    end

    def self.summary(transaction)
      "#{transaction.id}: #{transaction.type} #{transaction.booked_at.to_date} #{euros(transaction.amount)} " \
        "from #{transaction.debitor&.name} to #{transaction.creditor&.name}, interest on " \
        "#{transaction.interest_at.to_date}, #{transaction.category&.full_name || 'no category'}" \
        "#{charge(transaction)} - #{transaction.note}"
    end
    private_class_method :summary

    def self.charge(transaction)
      " charged to #{transaction.appropriation}" if transaction.appropriation
    end
    private_class_method :charge

    def self.parts(transaction)
      return "No parts." unless transaction.transaction_splits.exists?

      "Parts:\n#{parts_list(transaction)}"
    end
    private_class_method :parts

    def self.receipt(transaction)
      paid = transaction.receipt
      "Paid receipt ##{paid.id} from #{paid.shop.name}." if paid
    end
    private_class_method :receipt

    def self.chattels(transaction)
      bought = transaction.chattels.map { |chattel| "##{chattel.id} #{chattel.name}" }
      "Bought with it: #{bought.join(', ')}." if bought.any?
    end
    private_class_method :chattels
  end
end
