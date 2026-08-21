# Teaches the books to recognise a shop by another name on the bank statement
module Assistant
  class AddAccountAlias < Tool
    description "Give an external account another pattern to recognise it by in imported bank statements. " \
                "Patterns match case-insensitively anywhere in the merchant name."
    input_schema(
      properties: {
        account_id: { type: "integer", description: "The number identifying the account to recognise" },
        pattern: { type: "string", description: "The text to look for in the merchant name" }
      },
      required: [ "account_id", "pattern" ]
    )

    def self.call(account_id:, pattern:, server_context:)
      account = Account.find_by(id: account_id)
      return problem("No account ##{account_id} exists.") if account.nil?

      recognition = account.account_aliases.build(pattern: pattern)
      return problem(recognition.errors.full_messages.to_sentence) unless recognition.save

      answer("#{account} is now recognised by \"#{pattern}\".")
    end
  end
end
