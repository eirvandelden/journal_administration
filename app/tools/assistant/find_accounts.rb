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

      answer(accounts.map { |account| describe(account) }.join("\n"))
    end

    def self.describe(account)
      "#{account.id}: #{account} (#{account.external? ? "a shop or other outsider" : "ours"})"
    end
    private_class_method :describe
  end
end
