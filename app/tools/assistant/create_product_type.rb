# Lets an assistant add a kind of product
module Assistant
  class CreateProductType < Tool
    description "Create a product type booked to a category, so products of that type can be classified."
    input_schema(
      properties: {
        name: { type: "string", description: "The name, for example Naturel chips" },
        category_id: { type: "integer", description: "The category groceries of this type book to" }
      },
      required: [ "name", "category_id" ]
    )

    # Mirrors product_types#create
    def self.call(name:, category_id:, server_context:)
      category = Category.find_by(id: category_id)
      return problem("No category ##{category_id} exists.") if category.nil?

      type = ProductType.new(name: name, category: category)
      return refusal(type) unless type.save

      answer("Created product type ##{type.id} #{type.name}, books to #{category.full_name}.")
    end
  end
end
