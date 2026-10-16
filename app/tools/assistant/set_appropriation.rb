# Lets an assistant set what the household appropriates for a purpose, recipient and budget year
module Assistant
  class SetAppropriation < Tool
    description "Set the amount appropriated for one purpose (e.g. Birthday) and recipient (e.g. Etienne) " \
      "in one budget year. Creates the appropriation, or changes the amount of the existing one; " \
      "purpose and recipient are matched ignoring letter case."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        purpose: { type: "string", description: "What the money is for, e.g. Birthday" },
        recipient: { type: "string", description: "Who it is for, e.g. Etienne" },
        budget_year: { type: "integer", description: "The calendar year it is for, e.g. 2026" },
        amount: { type: "number", description: "The amount appropriated, more than zero" }
      },
      required: [ "purpose", "recipient", "budget_year", "amount" ]
    )

    # @return [MCP::Tool::Response]
    def self.call(purpose:, recipient:, budget_year:, amount:, server_context:)
      person = Appropriation.person_named(recipient)
      return problem("No person named #{recipient}.") unless person

      cents = cents_from(amount)
      return problem(two_decimals) if cents.nil?

      appropriation = Appropriation.named(purpose:, recipient: person.name, budget_year:).first ||
        Appropriation.new(purpose:, person:, budget_year:)
      saved = if appropriation.persisted?
        appropriation.update(amount: cents)
      else
        appropriation.update(amount: cents, recipient: person.name)
      end
      return problem(appropriation.errors.full_messages.to_sentence) unless saved

      answer("#{appropriation} (##{appropriation.id}) is set at #{euros(appropriation.amount)}.")
    end
  end
end
