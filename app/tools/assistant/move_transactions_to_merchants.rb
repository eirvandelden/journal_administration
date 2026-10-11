# Moves a shared payment provider's transactions to the merchants named in them
module Assistant
  class MoveTransactionsToMerchants < Tool
    description "Move every transaction on a shared payment provider to the merchant named in it. " \
      "A transaction that names no merchant stays. Categories chosen by hand and splits are kept. " \
      "Moving again moves nothing more."
    annotations destructive_hint: true
    input_schema(
      properties: {
        account_id: { type: "integer", description: "The number identifying the shared payment provider" }
      },
      required: [ "account_id" ]
    )

    def self.call(account_id:, server_context:)
      account = Account.find_by(id: account_id)
      return problem("No account ##{account_id} exists.") if account.nil?
      return problem("#{account} is not a shared payment provider, nothing was moved.") unless account.payment_provider?

      answer("Moved #{account.move_transactions_to_merchants} transactions from #{account} to their merchants.")
    rescue ActiveRecord::RecordInvalid => error
      problem("Moving failed and nothing was moved: #{error.message}")
    end
  end
end
