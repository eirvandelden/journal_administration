# Lets an assistant undo settling the wrong payment
module Assistant
  class UnlinkReceiptPayment < Tool
    description "Unlink a receipt from its payment. The splits already written on the payment stay."
    annotations idempotent_hint: true
    input_schema(
      properties: { receipt_id: { type: "integer", description: "The number identifying the receipt" } },
      required: [ "receipt_id" ]
    )

    # Mirrors receipts/payment_links#destroy
    def self.call(receipt_id:, server_context:)
      receipt = Receipt.find_by(id: receipt_id)
      return problem("No receipt ##{receipt_id} exists.") if receipt.nil?
      return answer("Receipt ##{receipt.id} was not linked to a payment.") if receipt.payment_id.nil?

      payment_id = receipt.payment_id
      return refusal(receipt) unless receipt.update(payment: nil)

      answer("Unlinked receipt ##{receipt.id} from payment ##{payment_id}. The splits already written stay.")
    end
  end
end
