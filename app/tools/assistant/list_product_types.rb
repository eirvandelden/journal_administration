# Tells the assistant every product type, the category each books to, and the brands in use
module Assistant
  class ListProductTypes < Tool
    description "List every product type with the number that identifies it and the category its " \
      "groceries book to, then the brands already in use."
    annotations read_only_hint: true

    def self.call(server_context:)
      types = ProductType.includes(category: :parent_category).order(:name)

      answer([
        *types.map { |type| "#{type.id}: #{type.name} - #{type.category.full_name}" },
        "Brands in use: #{Product.brands_in_use.join(', ').presence || 'none'}"
      ].join("\n"))
    end
  end
end
