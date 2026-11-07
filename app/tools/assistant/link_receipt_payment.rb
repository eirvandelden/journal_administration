# Lets an assistant settle a receipt against its bank payment and split the payment by the basket
module Assistant
  class LinkReceiptPayment < Tool
    description "Link a receipt to the payment that settled it and split that payment per category, the way " \
      "the basket divides. Answers with the splits written, so each can be charged with " \
      "charge_to_appropriation. Refused for a payment that does not fit (one the shop did not book around the " \
      "receipt's day, or one another receipt holds), a basket bigger than the payment, or a charged payment. " \
      "Linking the same payment again re-splits it."
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
    #: (receipt_id: Integer, transaction_id: Integer, server_context: untyped) -> MCP::Tool::Response
    def self.call(receipt_id:, transaction_id:, server_context:)
      receipt = Receipt.find_by(id: receipt_id)
      return problem("No receipt ##{receipt_id} exists.") if receipt.nil?

      payment = receipt.fitting_payments.find_by(id: transaction_id)
      return problem(not_fitting(receipt, transaction_id)) if payment.nil?

      refused = refused(receipt, payment)
      return problem(refused) if refused

      link(receipt, payment)
    end

    #: (Receipt receipt, Transaction payment) -> String?
    def self.refused(receipt, payment)
      return linked_elsewhere(receipt) if linked_elsewhere?(receipt, payment)
      return too_big(receipt, payment) unless receipt.basket_fits?(payment)

      "Payment ##{payment.id} is charged to an appropriation; remove that charge in the app first." if payment.charged?
    end
    private_class_method :refused

    #: (Receipt receipt) -> String
    def self.linked_elsewhere(receipt)
      "Receipt ##{receipt.id} is linked to payment ##{receipt.payment_id}; unlink it first."
    end
    private_class_method :linked_elsewhere

    #: (Receipt receipt, Transaction payment) -> String
    def self.too_big(receipt, payment)
      "The basket (#{euros(receipt.basket_total)}) is bigger than the payment (#{euros(payment.amount)})."
    end
    private_class_method :too_big

    #: (Receipt receipt, Transaction payment) -> bool
    def self.linked_elsewhere?(receipt, payment) = receipt.payment_id && receipt.payment_id != payment.id
    private_class_method :linked_elsewhere?

    #: (Receipt receipt, Transaction payment) -> MCP::Tool::Response
    def self.link(receipt, payment)
      split = Receipt.transaction do
        receipt.update!(payment: payment)
        receipt.rewrite_payment_splits
      end
      return answer("Linked receipt ##{receipt.id} to payment ##{payment.id}. #{unsplit_reason(receipt)}") unless split

      answer("Linked receipt ##{receipt.id} to payment ##{payment.id}. Splits:\n#{parts_list(payment)}" \
        "#{remainder_reason(receipt)}")
    end
    private_class_method :link

    #: (Receipt receipt) -> String
    def self.unsplit_reason(receipt)
      return nothing_to_split if unclassified_products(receipt).empty?

      "The payment is not split: #{classify_first(receipt)}"
    end
    private_class_method :unsplit_reason

    #: (Receipt receipt) -> String
    def self.remainder_reason(receipt)
      return "" if unclassified_products(receipt).empty?

      "\nThe remainder split holds the share of the unclassified products; #{classify_first(receipt)} " \
        "Then link again to split it further."
    end
    private_class_method :remainder_reason

    #: (Receipt receipt) -> String
    def self.classify_first(receipt)
      "classify these products with classify_product: " \
        "#{unclassified_products(receipt).map { |product| "##{product.id} #{product.name}" }.join(', ')}."
    end
    private_class_method :classify_first

    #: (Receipt receipt) -> Array[Product]
    def self.unclassified_products(receipt)
      receipt.lines.includes(product: { product_type: :category }).filter_map do |line|
        line.product if line.category.nil? && line.paid_amount.positive?
      end.uniq
    end
    private_class_method :unclassified_products

    #: () -> String
    def self.nothing_to_split
      "The basket has nothing to split (no lines, or only free ones); the payment is not split."
    end
    private_class_method :nothing_to_split

    #: (Receipt receipt, Integer transaction_id) -> String
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
