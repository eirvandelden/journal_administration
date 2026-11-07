# Shows an assistant one receipt with its basket and the payments it could be settled against
module Assistant
  class ShowReceipt < Tool
    description "Show a receipt: shop, day, total, each line with its product number, and the payments that " \
      "could have settled it."
    annotations read_only_hint: true
    input_schema(
      properties: { receipt_id: { type: "integer", description: "The number identifying the receipt" } },
      required: [ "receipt_id" ]
    )

    # Mirrors receipts#show
    #: (receipt_id: Integer, server_context: untyped) -> MCP::Tool::Response
    def self.call(receipt_id:, server_context:)
      receipt = Receipt.find_by(id: receipt_id)
      return problem("No receipt ##{receipt_id} exists.") if receipt.nil?

      answer(receipt_description(receipt))
    end
  end
end
