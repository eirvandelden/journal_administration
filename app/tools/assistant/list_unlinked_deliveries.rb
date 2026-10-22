# Tells the assistant which Albert Heijn deliveries no payment is linked to yet
module Assistant
  class ListUnlinkedDeliveries < Tool
    description "List the Albert Heijn deliveries that no payment is linked to, oldest first, for a person " \
      "to confirm on the receipts page."
    annotations read_only_hint: true

    def self.call(server_context:)
      answer(describe(Receipt.unlinked_deliveries.order(:issued_on, :id)))
    end

    # @param deliveries [Enumerable<Receipt>]
    # @return [String]
    def self.describe(deliveries)
      lines = deliveries.map do |delivery|
        "Receipt ##{delivery.id}: order #{delivery.order_number} on #{delivery.issued_on}, " \
          "#{euros(delivery.total_amount)} in total"
      end

      lines.presence&.join("\n") || "Every delivery is linked to a payment."
    end
  end
end
