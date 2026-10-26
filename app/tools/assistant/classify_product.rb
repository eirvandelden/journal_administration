# Lets an assistant fill in a product's brand and product type
module Assistant
  class ClassifyProduct < Tool
    description "Fill in the brand and the product type of a product. A brand or type the product already " \
      "has is never replaced, and the answer says so. Both are optional."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        product_id: { type: "integer", description: "The number identifying the product" },
        brand: { type: "string", description: "The brand, such as AH" },
        product_type_id: { type: "integer", description: "The number identifying the product type" }
      },
      required: [ "product_id" ]
    )

    def self.call(product_id:, server_context:, brand: nil, product_type_id: nil)
      product = Product.find_by(id: product_id)
      return problem("No product ##{product_id} exists.") if product.nil?

      type = ProductType.find_by(id: product_type_id) if product_type_id
      return problem("No product type ##{product_type_id} exists.") if product_type_id && type.nil?

      fill_in(product, brand, type)
    end

    def self.fill_in(product, brand, type)
      kept = kept_from(product, brand, type)
      return problem(product.errors.full_messages.to_sentence) unless product.fill_in(brand: brand, product_type: type)

      answer([ describe(product), (sentence_about(kept) if kept.any?) ].compact.join(" "))
    end
    private_class_method :fill_in

    def self.describe(product)
      "Product ##{product.id} #{product.name}: #{product.brand.presence || 'no brand'}, " \
        "#{product.product_type&.name || 'no type'}."
    end
    private_class_method :describe

    def self.sentence_about(kept) = "Kept #{kept.to_sentence}, as already set."
    private_class_method :sentence_about

    def self.kept_from(product, brand, type)
      [ ("the brand #{product.brand}" if kept_brand?(product, brand)),
        ("the type #{product.product_type.name}" if kept_type?(product, type)) ].compact
    end
    private_class_method :kept_from

    def self.kept_brand?(product, brand) = brand.present? && product.brand.present? && product.brand != brand.strip
    private_class_method :kept_brand?

    def self.kept_type?(product, type) = type && product.product_type && product.product_type != type
    private_class_method :kept_type?
  end
end
