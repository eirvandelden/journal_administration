# Lets an assistant file a pasted grocery receipt with its lines
module Assistant
  class FileReceipt < Tool
    description "File a receipt with its lines in one step. Products are found by name; a name nobody has " \
      "seen becomes an unclassified product (see classify_product). Refused when the same shop, day and " \
      "total, or the same order number, is already filed. Link it to its payment with link_receipt_payment."
    input_schema(
      properties: {
        shop_id: { type: "integer", description: "The account of the shop; find it with find_accounts" },
        issued_on: { type: "string", description: "The invoice day, written as 2026-08-01" },
        total_amount: { type: "number", description: "The total the invoice states, in euros" },
        order_number: { type: "string", description: "The shop's order number, when it has one" },
        lines: {
          type: "array",
          description: "The lines on the invoice",
          items: {
            type: "object",
            properties: {
              name: { type: "string", description: "The product's name as the invoice prints it" },
              quantity: { type: "number", description: "How many were bought" },
              full_amount: { type: "number", description: "The shelf price of the line in euros" },
              discount_amount: { type: "number", description: "The bonus in euros; 0 when there is none" }
            },
            required: [ "name", "quantity", "full_amount" ]
          }
        }
      },
      required: [ "shop_id", "issued_on", "total_amount", "lines" ]
    )

    # Has no route: the UI only imports receipts
    def self.call(shop_id:, issued_on:, total_amount:, lines:, server_context:, order_number: nil)
      shop = Account.find_by(id: shop_id)
      return problem("No account ##{shop_id} exists.") if shop.nil?
      return problem("#{shop} is one of our own accounts; a receipt comes from a shop.") unless shop.external?

      issued = day(issued_on)
      total = cents_from(total_amount)
      return problem("Write days as 2026-08-01.") if issued.nil?
      return problem(two_decimals) if total.nil?

      basket = basket_from(lines)
      return basket if basket.is_a?(MCP::Tool::Response)

      file(shop, issued, total, basket, order_number.presence)
    end

    def self.file(shop, issued_on, total_amount, lines, order_number)
      receipt = Receipt.file(shop:, issued_on:, total_amount:, lines:, order_number:)
      return refusal(receipt) unless receipt.persisted?

      answer("Filed receipt ##{receipt.id}.\n#{ShowReceipt.call(receipt_id: receipt.id, server_context: nil)
        .content.first[:text]}")
    end
    private_class_method :file

    def self.basket_from(lines)
      return problem("A receipt needs at least one line.") if lines.empty?

      lines.map { |line| basket_line(line.to_h.with_indifferent_access) }.then do |basket|
        basket.find { |line| line.is_a?(MCP::Tool::Response) } || basket
      end
    end
    private_class_method :basket_from

    def self.basket_line(line)
      full = cents_from(line[:full_amount])
      discount = cents_from(line[:discount_amount] || 0)
      return problem("Every line needs a product name.") if line[:name].to_s.strip.empty?
      return problem(two_decimals) if full.nil? || discount.nil?

      { name: line[:name], quantity: line[:quantity], full_amount: full, discount_amount: discount }
    end
    private_class_method :basket_line
  end
end
