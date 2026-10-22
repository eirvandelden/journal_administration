# Tells the assistant which products still need a brand or a product type
module Assistant
  class ListUnclassifiedProducts < Tool
    HIGHEST_COUNT = 250

    description "List the products that still lack a brand or a product type, with the number that " \
      "identifies each. At most #{HIGHEST_COUNT} are listed."
    annotations read_only_hint: true

    def self.call(server_context:)
      products = Product.unclassified.includes(:product_type).order(:name).limit(HIGHEST_COUNT).to_a

      answer([ *products.map { |product| describe(product) }, held_back(products) ].compact.join("\n"))
    end

    def self.describe(product)
      "#{product.id}: #{product.name} (#{product.brand.presence || 'no brand'}, " \
        "#{product.product_type&.name || 'no type'})"
    end
    private_class_method :describe

    # A list believed to be complete is classified as if nothing were left, so a shortened one says so.
    def self.held_back(products)
      return nil if products.length < HIGHEST_COUNT

      total = Product.unclassified.count
      return nil if total <= products.length

      "Showing #{products.length} of #{total} products - the rest are on the products page."
    end
    private_class_method :held_back
  end
end
