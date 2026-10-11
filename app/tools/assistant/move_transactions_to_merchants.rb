# Moves a shared payment provider's transactions to the merchants named in them
module Assistant
  class MoveTransactionsToMerchants < Tool
    description "Move every transaction on a shared payment provider to the merchant named in it. " \
      "A transaction that names no merchant stays. A transaction still on the provider's default category " \
      "gets the merchant's default category, or none when the merchant has none. " \
      "Categories chosen by hand and splits are kept. " \
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

      answer(moved(account.move_transactions_to_merchants, account))
    rescue PaymentProvider::MoveFailed => error
      problem("Moving failed and nothing was moved: #{error.message}")
    end

    def self.moved(count, account)
      return "Moved 1 transaction from #{account} to its merchant." if count == 1

      "Moved #{count} transactions from #{account} to their merchants."
    end
    private_class_method :moved
  end
end
