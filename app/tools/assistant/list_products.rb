# Shows an assistant the products that came off receipts
module Assistant
  class ListProducts < Tool
    DEFAULT_LIMIT = 25
    HIGHEST_LIMIT = 100

    description "List products by name with brand and product type, flagging the unclassified ones; " \
      "list_unclassified_products lists only those."
    annotations read_only_hint: true
    input_schema(
      properties: {
        limit: { type: "integer", description: "How many to list at most (#{DEFAULT_LIMIT} by default, " \
          "#{HIGHEST_LIMIT} at the very most)" }
      }
    )

    # Mirrors products#index
    #: (server_context: untyped, ?limit: Integer) -> MCP::Tool::Response
    def self.call(server_context:, limit: DEFAULT_LIMIT)
      products = Product.includes(:product_type).order(:normalized_name)
      return answer("No product is known yet.") if products.none?

      shown = products.limit(limit.clamp(1, HIGHEST_LIMIT)).to_a
      answer([ *shown.map(&:summary), held_back(products, shown) ].compact.join("\n"))
    end

    #: (ActiveRecord::Relation products, Array[Product] shown) -> String?
    def self.held_back(products, shown)
      total = products.count
      return nil if total <= shown.length

      "Showing #{shown.length} of #{total} products."
    end
    private_class_method :held_back
  end
end
