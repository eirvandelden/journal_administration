# Lets an assistant rename a kind of product or move it to another category
module Assistant
  class UpdateProductType < Tool
    description "Rename a product type or change the category it books to."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        product_type_id: { type: "integer", description: "The number identifying the product type" },
        name: { type: "string", description: "The new name" },
        category_id: { type: "integer", description: "The new category" }
      },
      required: [ "product_type_id" ]
    )

    # Mirrors product_types#update
    def self.call(product_type_id:, server_context:, category_id: nil, **changes)
      type = ProductType.find_by(id: product_type_id)
      return problem("No product type ##{product_type_id} exists.") if type.nil?

      category = Category.find_by(id: category_id) if category_id
      return problem("No category ##{category_id} exists.") if category_id && category.nil?

      attributes = category ? changes.slice(:name).merge(category: category) : changes.slice(:name)
      return refusal(type) unless type.update(attributes)

      answer("Updated product type ##{type.id} #{type.name}, books to #{type.category.full_name}.")
    end
  end
end
