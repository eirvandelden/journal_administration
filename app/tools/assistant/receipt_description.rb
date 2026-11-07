# How an assistant is told about a receipt: its shop, its basket and the payments it could be linked to
module Assistant
  module ReceiptDescription
    private

    def receipt_description(receipt)
      [ receipt_summary(receipt), receipt_lines(receipt), fitting_payments_list(receipt) ].compact.join("\n")
    end

    def receipt_summary(receipt)
      payment = receipt.payment_id ? "settled by payment ##{receipt.payment_id}" : "no payment linked"
      "#{receipt.id}: #{receipt.issued_on} #{receipt.shop.name} #{euros(receipt.total_amount)}, " \
        "basket #{euros(receipt.basket_total)}, #{payment}"
    end

    def receipt_lines(receipt)
      lines = receipt.lines.includes(product: { product_type: { category: :parent_category } }).order(:id).map do |line|
        "  line #{line.id}: product ##{line.product_id} #{line.product.name}, #{line.quantity} x, " \
          "paid #{euros(line.paid_amount)} (shelf #{euros(line.full_amount)}), " \
          "#{line.category&.full_name || 'unclassified'}"
      end
      lines.empty? ? "No lines." : "Lines:\n#{lines.join("\n")}"
    end

    def fitting_payments_list(receipt)
      return if receipt.payment_id

      payments = receipt.fitting_payments.map do |payment|
        "  #{payment.id}: #{payment.booked_at.to_date} #{euros(payment.amount)} #{payment.note}".rstrip
      end
      "Payments it could be linked to:\n#{payments.join("\n")}" if payments.any?
    end
  end
end
