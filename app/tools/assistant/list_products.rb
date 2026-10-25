# Shows an assistant the products that came off receipts
module Assistant
  class ListProducts < Tool
    DEFAULT_LIMIT = 25
    HIGHEST_LIMIT = 100

    description "List products by name with brand and product type; ask for only the unclassified ones to see " \
      "what still needs classifying."
    annotations read_only_hint: true
    input_schema(
      properties: {
        unclassified: { type: "boolean", description: "Only products without a brand or a product type" },
        limit: { type: "integer", description: "How many to list at most (#{DEFAULT_LIMIT} by default, " \
          "#{HIGHEST_LIMIT} at the very most)" }
      }
    )

    # Mirrors products#index
    def self.call(server_context:, unclassified: false, limit: DEFAULT_LIMIT)
      products = unclassified ? Product.unclassified : Product.all
      products = products.includes(:product_type).order(:normalized_name)
      return answer(unclassified ? "Every product is classified." : "No product is known yet.") if products.none?

      shown = products.limit(limit.clamp(1, HIGHEST_LIMIT)).to_a
      answer([ *shown.map { |product| describe(product) }, held_back(products, shown) ].compact.join("\n"))
    end

    def self.describe(product)
      "#{product.id}: #{product.name}, brand #{product.brand.presence || 'none'}, " \
        "type #{product.product_type&.name || 'none'}#{' (unclassified)' if product.unclassified?}"
    end
    private_class_method :describe

    def self.held_back(products, shown)
      total = products.count
      return nil if total <= shown.length

      "Showing #{shown.length} of #{total} products."
    end
    private_class_method :held_back
  end
end
