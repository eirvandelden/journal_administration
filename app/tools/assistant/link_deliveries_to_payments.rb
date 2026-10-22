# Lets an assistant link deliveries to the payments that confidently paid them
module Assistant
  class LinkDeliveriesToPayments < Tool
    description "Link every unlinked Albert Heijn delivery to its payment when the bank note names the order " \
      "number, or when exactly one door-card payment fits, and split that payment by the basket. Call it once, " \
      "after every mail is imported and the products are classified: it replaces the splits of the payments " \
      "it links. Answers the deliveries it linked, then every delivery left for a person to confirm."
    annotations destructive_hint: true

    def self.call(server_context:)
      linked = Receipt.link_payments

      answer([ *linked.map { |delivery| describe(delivery) }, "", leftovers ].join("\n").strip)
    end

    def self.describe(delivery)
      payment = delivery.payment

      "Linked order #{delivery.order_number} to payment ##{payment.id} of #{euros(payment.amount)} " \
        "booked on #{payment.booked_at.to_date}."
    end
    private_class_method :describe

    def self.leftovers
      "Not linked: #{ListUnlinkedDeliveries.describe(Receipt.unlinked_deliveries.order(:issued_on, :id))}"
    end
    private_class_method :leftovers
  end
end
