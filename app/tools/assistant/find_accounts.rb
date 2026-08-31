# Finds the accounts an assistant can point a transaction or a pattern at
module Assistant
  class FindAccounts < Tool
    description "Search accounts by name or account number, with the number that identifies each one."
    annotations read_only_hint: true
    input_schema(
      properties: {
        query: { type: "string", description: "Part of the name or account number to search for" }
      },
      required: [ "query" ]
    )

    def self.call(query:, server_context:)
      accounts = Account.search(query)

      return answer("No account matches #{query}.") if accounts.empty?

      answer([ *accounts.map { |account| describe(account) }, held_back(accounts) ].compact.join("\n"))
    end

    def self.describe(account)
      "#{account.id}: #{account} (#{account.external? ? "a shop or other outsider" : "ours"})"
    end
    private_class_method :describe

    # The search keeps its own ceiling, so an assistant reading the list must be told when the
    # answer is only part of it — silence reads as "these are all of them".
    def self.held_back(accounts)
      matches = accounts.limit(nil).count

      return nil if matches <= accounts.length

      "Showing #{accounts.length} of #{matches} matches - narrow the query to see the rest."
    end
    private_class_method :held_back
  end
end
