# Lets an assistant remove a receipt that should not be on file
module Assistant
  class DeleteReceipt < Tool
    description "Delete a receipt and its lines. Splits already written on its payment stay."
    annotations destructive_hint: true
    input_schema(
      properties: { receipt_id: { type: "integer", description: "The number identifying the receipt" } },
      required: [ "receipt_id" ]
    )

    # Has no route: the UI never deletes a receipt
    def self.call(receipt_id:, server_context:)
      receipt = Receipt.find_by(id: receipt_id)
      return problem("No receipt ##{receipt_id} exists.") if receipt.nil?
      return refusal(receipt) unless receipt.destroy

      answer("Deleted receipt ##{receipt_id} and its lines. The splits already written on its payment stay.")
    end
  end
end
