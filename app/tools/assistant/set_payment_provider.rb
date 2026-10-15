# Marks an external account as a payment provider that collects for many merchants, or unmarks it
module Assistant
  class SetPaymentProvider < Tool
    description "Mark an external account as a shared payment provider, such as Adyen or Mollie, " \
      "or unmark it. Payments imported through a shared provider are booked on the merchant " \
      "named in the transaction instead of on the provider. Existing transactions stay where they " \
      "are until move_transactions_to_merchants runs."
    annotations destructive_hint: true
    input_schema(
      properties: {
        account_id: { type: "integer", description: "The number identifying the external account" },
        shared: { type: "boolean", description: "True to mark it as a shared payment provider, false to unmark it" }
      },
      required: [ "account_id", "shared" ]
    )

    def self.call(account_id:, shared:, server_context:)
      account = Account.find_by(id: account_id)
      return problem("No account ##{account_id} exists.") if account.nil?
      return problem(account.errors.full_messages.to_sentence) unless account.update(payment_provider: shared)

      answer("#{account} is #{shared ? 'now' : 'no longer'} a shared payment provider.")
    end
  end
end
