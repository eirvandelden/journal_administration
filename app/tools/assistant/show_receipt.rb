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
    def self.call(receipt_id:, server_context:)
      receipt = Receipt.find_by(id: receipt_id)
      return problem("No receipt ##{receipt_id} exists.") if receipt.nil?

      answer([ summary(receipt), lines(receipt), fitting(receipt) ].compact.join("\n"))
    end

    def self.summary(receipt)
      payment = receipt.payment_id ? "settled by payment ##{receipt.payment_id}" : "no payment linked"
      "#{receipt.id}: #{receipt.issued_on} #{receipt.shop.name} #{euros(receipt.total_amount)}, " \
        "basket #{euros(receipt.basket_total)}, #{payment}"
    end
    private_class_method :summary

    def self.lines(receipt)
      lines = receipt.lines.includes(product: { product_type: :category }).order(:id).map do |line|
        "  line #{line.id}: product ##{line.product_id} #{line.product.name}, #{line.quantity} x, " \
          "paid #{euros(line.paid_amount)} (shelf #{euros(line.full_amount)}), " \
          "#{line.category&.full_name || 'unclassified'}"
      end
      lines.empty? ? "No lines." : "Lines:\n#{lines.join("\n")}"
    end
    private_class_method :lines

    def self.fitting(receipt)
      payments = receipt.fitting_payments.includes(:debitor).map do |payment|
        "  #{payment.id}: #{payment.booked_at.to_date} #{euros(payment.amount)} #{payment.note}".rstrip
      end
      "Payments it could be linked to:\n#{payments.join("\n")}" if payments.any? && receipt.payment_id.nil?
    end
    private_class_method :fitting
  end
end
