module Importing
  module AlbertHeijn
    # Records the basket from an Albert Heijn packing slip mail
    #
    # A delivery is identified by its order number, so a slip that arrives twice
    # — Albert Heijn sends a fresh one whenever the order changes — updates the
    # delivery already recorded instead of adding a second one, and splits its
    # payment again so the books follow the corrected basket. Which payment
    # settled it is left to a person: empties are settled at the door, so the
    # amount the bank took rarely equals the slip's total.
    class ImportJob < ApplicationJob
      queue_as :default

      # @param mail [String] the packing slip mail as text
      # @return [void]
      def perform(mail)
        slip = PackingSlip.parse(mail)
        return if slip.blank?

        Receipt.transaction { record(slip) }
      end

      private

      def record(slip)
        receipt = Receipt.find_or_initialize_by(order_number: slip.order_number)
        receipt.update!(shop: shop, issued_on: slip.delivered_on, total_amount: slip.total_amount)
        receipt.lines.destroy_all
        slip.lines.each { |line| receipt.lines.create!(line_attributes(line)) }
        receipt.rewrite_payment_splits
      end

      def shop
        Account.resolve_for_import(account_number: nil, description: "", name: "Albert Heijn")
      end

      def line_attributes(line)
        {
          product: Product.resolve_by_name(line.name),
          quantity: line.quantity,
          full_amount: line.full_amount,
          discount_amount: line.discount_amount,
          paid_amount: line.paid_amount
        }
      end
    end
  end
end
