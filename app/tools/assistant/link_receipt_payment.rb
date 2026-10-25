# Lets an assistant settle a receipt against its bank payment and split the payment by the basket
module Assistant
  class LinkReceiptPayment < Tool
    description "Link a receipt to the payment that settled it and split that payment per category, the way " \
      "the basket divides. Answers with the splits written, so each can be charged with " \
      "charge_to_appropriation. Refused for a payment that does not fit, a basket bigger than the payment, a " \
      "charged payment, or a payment that paid another receipt. Linking the same payment again re-splits it."
    annotations destructive_hint: true
    input_schema(
      properties: {
        receipt_id: { type: "integer", description: "The number identifying the receipt" },
        transaction_id: {
          type: "integer", description: "The number identifying the payment; show_receipt lists the fitting ones"
        }
      },
      required: [ "receipt_id", "transaction_id" ]
    )

    # Mirrors receipts/payment_links#create
    def self.call(receipt_id:, transaction_id:, server_context:)
      receipt = Receipt.find_by(id: receipt_id)
      return problem("No receipt ##{receipt_id} exists.") if receipt.nil?

      payment = receipt.fitting_payments.find_by(id: transaction_id)
      return problem(not_fitting(receipt, transaction_id)) if payment.nil?

      refused = refused(receipt, payment)
      return problem(refused) if refused

      link(receipt, payment)
    end

    def self.refused(receipt, payment)
      return linked_elsewhere(receipt) if linked_elsewhere?(receipt, payment)
      return "Payment ##{payment.id} already paid receipt ##{payment.receipt.id}." if paid_another?(receipt, payment)
      return too_big(receipt, payment) unless receipt.basket_fits?(payment)

      "Payment ##{payment.id} is charged to an appropriation; remove that charge in the app first." if payment.charged?
    end
    private_class_method :refused

    def self.linked_elsewhere(receipt)
      "Receipt ##{receipt.id} is linked to payment ##{receipt.payment_id}; unlink it first."
    end
    private_class_method :linked_elsewhere

    def self.too_big(receipt, payment)
      "The basket (#{euros(receipt.basket_total)}) is bigger than the payment (#{euros(payment.amount)})."
    end
    private_class_method :too_big

    def self.linked_elsewhere?(receipt, payment) = receipt.payment_id && receipt.payment_id != payment.id
    private_class_method :linked_elsewhere?

    def self.paid_another?(receipt, payment) = payment.receipt && payment.receipt != receipt
    private_class_method :paid_another?

    def self.link(receipt, payment)
      split = Receipt.transaction do
        receipt.update!(payment: payment)
        receipt.rewrite_payment_splits
      end
      return answer("Linked receipt ##{receipt.id} to payment ##{payment.id}. #{unsplit_reason(receipt)}") unless split

      answer("Linked receipt ##{receipt.id} to payment ##{payment.id}. Splits:\n#{parts_list(payment)}")
    end
    private_class_method :link

    def self.unsplit_reason(receipt)
      unclassified = receipt.lines.includes(:product).filter_map { |line| line.product if line.category.nil? }.uniq
      return nothing_to_split if unclassified.empty?

      "The payment is not split: classify these products first with classify_product: " \
        "#{unclassified.map { |product| "##{product.id} #{product.name}" }.join(', ')}."
    end
    private_class_method :unsplit_reason

    def self.nothing_to_split
      "The basket has nothing to split (no lines, or only free ones); the payment is not split."
    end
    private_class_method :nothing_to_split

    def self.not_fitting(receipt, transaction_id)
      fitting = receipt.fitting_payments.map do |payment|
        "#{payment.id}: #{payment.booked_at.to_date} #{euros(payment.amount)}"
      end
      "Transaction ##{transaction_id} does not fit receipt ##{receipt.id}. " \
        "#{fitting.any? ? "Fitting payments:\n#{fitting.join("\n")}" : 'No payment fits it.'}"
    end
    private_class_method :not_fitting
  end
end
