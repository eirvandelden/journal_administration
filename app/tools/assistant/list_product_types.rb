# Shows an assistant the kinds of product and the category each books to
module Assistant
  class ListProductTypes < Tool
    description "List the product types with the category each one books to."
    annotations read_only_hint: true
    input_schema(properties: {})

    # Mirrors product_types#index
    def self.call(server_context:)
      types = ProductType.includes(:category).order(:name)
      return answer("No product type exists yet.") if types.none?

      answer(types.map { |type| "#{type.id}: #{type.name}, books to #{type.category.full_name}" }.join("\n"))
    end
  end
end
