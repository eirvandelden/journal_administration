# Lets an assistant give a product its brand and product type
module Assistant
  class ClassifyProduct < Tool
    description "Classify a product: set its brand and product type, and optionally correct its name. A " \
      "classified product books to its product type's category when a receipt splits a payment."
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
    def self.call(product_id:, server_context:, product_type_id: nil, **changes)
      product = Product.find_by(id: product_id)
      return problem("No product ##{product_id} exists.") if product.nil?

      type = ProductType.find_by(id: product_type_id) if product_type_id
      return problem("No product type ##{product_type_id} exists.") if product_type_id && type.nil?

      attributes = type ? changes.slice(:name, :brand).merge(product_type: type) : changes.slice(:name, :brand)
      return refusal(product) unless product.update(attributes)

      answer("Updated product ##{product.id}: #{ListProducts.send(:describe, product)}")
    end
  end
end
