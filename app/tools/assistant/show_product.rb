# Shows an assistant one product and what it cost each time
module Assistant
  class ShowProduct < Tool
    description "Show a product with its brand, product type and the purchases of it, newest first."
    annotations read_only_hint: true
    input_schema(
      properties: { product_id: { type: "integer", description: "The number identifying the product" } },
      required: [ "product_id" ]
    )

    # Mirrors products#show
    def self.call(product_id:, server_context:)
      product = Product.find_by(id: product_id)
      return problem("No product ##{product_id} exists.") if product.nil?

      purchases = product.purchases.limit(10).map do |line|
        "  receipt ##{line.receipt_id} #{line.receipt.issued_on}: #{line.quantity} x, paid #{euros(line.paid_amount)}"
      end
      answer([ ListProducts.send(:describe, product), *("Purchases:" if purchases.any?), *purchases ].join("\n"))
    end
  end
end
