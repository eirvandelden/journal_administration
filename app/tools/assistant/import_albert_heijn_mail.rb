# Lets an assistant hand over one Albert Heijn basket mail, so its delivery is recorded
module Assistant
  class ImportAlbertHeijnMail < Tool
    description "Record the delivery that one Albert Heijn mail describes, a packing slip (pakbon) or an " \
      "order confirmation. Pass the plain text of the mail. Handing over the same mail again changes nothing, " \
      "and a packing slip replaces what an order confirmation listed. Import every mail first, then classify " \
      "the products, and call link_deliveries_to_payments last."
    annotations idempotent_hint: true
    input_schema(
      properties: { mail: { type: "string", description: "The plain-text body of one Albert Heijn mail" } },
      required: [ "mail" ]
    )

    def self.call(mail:, server_context:)
      basket = Importing::AlbertHeijn::BasketMail.parse(mail)
      return problem("No Albert Heijn basket could be read from this mail, so nothing was saved.") if basket.nil?

      if basket.delivered_on < Receipt::Recordable::FIRST_DELIVERY_ON
        return problem("Order #{basket.order_number} was delivered on #{basket.delivered_on}, before " \
          "#{Receipt::Recordable::FIRST_DELIVERY_ON}, so nothing was saved.")
      end

      describe(Receipt.record_basket(basket), basket)
    end

    def self.describe(receipt, basket)
      kept = receipt.packed? && !basket.packed?
      products = receipt.lines.includes(:product).map(&:product)
      unclassified = products.filter_map { |product| product.id if product.unclassified? }.uniq

      answer([
        "Receipt ##{receipt.id}: order #{receipt.order_number} delivered on #{receipt.issued_on}, " \
          "#{receipt.lines.count} lines, #{receipt.packed? ? 'packed' : 'ordered'}.",
        (kept ? "Kept the packed basket already recorded over this order confirmation." : nil),
        "Unclassified products: #{unclassified.join(', ').presence || 'none'}."
      ].compact.join("\n"))
    end
    private_class_method :describe
  end
end
