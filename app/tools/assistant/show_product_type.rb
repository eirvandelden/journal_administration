# Shows an assistant one product type and its products compared by their latest price
module Assistant
  class ShowProductType < Tool
    description "Show a product type with its category and the latest purchase of each product of that type."
    annotations read_only_hint: true
    input_schema(
      properties: { product_type_id: { type: "integer", description: "The number identifying the product type" } },
      required: [ "product_type_id" ]
    )

    # Mirrors product_types#show
    def self.call(product_type_id:, server_context:)
      type = ProductType.find_by(id: product_type_id)
      return problem("No product type ##{product_type_id} exists.") if type.nil?

      latest = type.latest_purchase_per_product.map do |product, line|
        "  product ##{product.id} #{product.name}: paid #{euros(line.paid_amount)} on #{line.receipt.issued_on}"
      end
      answer([ "#{type.id}: #{type.name}, books to #{type.category.full_name}", *latest ].join("\n"))
    end
  end
end
