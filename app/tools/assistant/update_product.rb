# Lets an assistant edit a product the way the products page does, replacing what it already had
module Assistant
  class UpdateProduct < Tool
    description "Edit a product: rename it, or replace its brand or product type, even one already set. Only " \
      "what is given changes. To fill in only what is still blank, use classify_product."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        product_id: { type: "integer", description: "The number identifying the product" },
        name: { type: "string", description: "A corrected name" },
        brand: { type: "string", description: "The brand, for example AH" },
        product_type_id: { type: "integer", description: "The product type; list_product_types shows them" }
      },
      required: [ "product_id" ]
    )

    # Mirrors products#update
    #: (product_id: Integer, server_context: untyped, ?product_type_id: Integer?, **untyped) -> MCP::Tool::Response
    def self.call(product_id:, server_context:, product_type_id: nil, **changes)
      product = Product.find_by(id: product_id)
      return problem("No product ##{product_id} exists.") if product.nil?

      type = ProductType.find_by(id: product_type_id) if product_type_id
      return problem("No product type ##{product_type_id} exists.") if product_type_id && type.nil?

      attributes = type ? changes.slice(:name, :brand).merge(product_type: type) : changes.slice(:name, :brand)
      return refusal(product) unless product.update(attributes)

      answer("Updated product #{product.summary}")
    end
  end
end
