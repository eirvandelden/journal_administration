# Lets an assistant name a kind of product, such as "Naturel chips", and say where it books to
module Assistant
  class CreateProductType < Tool
    description "Find the product type with this name, whatever its case, or create it under the given " \
      "category. A type that exists keeps its category. Any category but Transfer may be used."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        name: { type: "string", description: "A Dutch shopping word for what the product is, such as Naturel chips" },
        category_id: { type: "integer", description: "The number identifying the category its groceries book to" }
      },
      required: [ "name", "category_id" ]
    )

    def self.call(name:, category_id:, server_context:)
      category = Category.find_by(id: category_id)
      return problem("No category ##{category_id} exists.") if category.nil?
      return problem("Product types never book to the #{Category::TRANSFER_NAME} category.") if category.transfer?

      existing = ProductType.find { |type| type.name.casecmp?(name.strip) }
      return answer("Product type ##{existing.id} #{existing.name} already exists and books to " \
        "#{existing.category.full_name}.") if existing

      create(name.strip, category)
    end

    def self.create(name, category)
      type = ProductType.new(name: name, category: category)
      return problem(type.errors.full_messages.to_sentence) unless type.save

      answer("Product type ##{type.id} #{type.name} books to #{category.full_name}.")
    end
    private_class_method :create
  end
end
