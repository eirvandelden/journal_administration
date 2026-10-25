# Shows an assistant the grocery receipts on file
module Assistant
  class ListReceipts < Tool
    DEFAULT_LIMIT = 25
    HIGHEST_LIMIT = 100

    description "List the receipts on file, newest first, with shop, day, total and the payment each settled."
    annotations read_only_hint: true
    input_schema(
      properties: {
        limit: { type: "integer", description: "How many to list at most (#{DEFAULT_LIMIT} by default, " \
          "#{HIGHEST_LIMIT} at the very most)" }
      }
    )

    # Mirrors receipts#index
    def self.call(server_context:, limit: DEFAULT_LIMIT)
      receipts = Receipt.includes(:shop).order(issued_on: :desc, id: :desc)
      return answer("No receipt is on file.") if receipts.none?

      shown = receipts.limit(limit.clamp(1, HIGHEST_LIMIT)).to_a
      answer([ *shown.map { |receipt| describe(receipt) }, held_back(receipts, shown) ].compact.join("\n"))
    end

    def self.describe(receipt)
      payment = receipt.payment_id ? "payment ##{receipt.payment_id}" : "no payment linked"
      "#{receipt.id}: #{receipt.issued_on} #{receipt.shop.name} #{euros(receipt.total_amount)}, #{payment}"
    end
    private_class_method :describe

    def self.held_back(receipts, shown)
      total = receipts.count
      return nil if total <= shown.length

      "Showing #{shown.length} of #{total} receipts."
    end
    private_class_method :held_back
  end
end
