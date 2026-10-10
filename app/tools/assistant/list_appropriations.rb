# Tells the assistant what the household appropriated for one budget year and what is left of it
module Assistant
  class ListAppropriations < Tool
    description "List the appropriations of one budget year: for each, its number, purpose, recipient, " \
      "the amount appropriated, the amount charged to it and the balance left. A negative balance is overspent."
    annotations read_only_hint: true
    input_schema(
      properties: {
        budget_year: { type: "integer", description: "The calendar year the appropriations are for, e.g. 2026" }
      },
      required: [ "budget_year" ]
    )

    # @return [MCP::Tool::Response]
    def self.call(budget_year:, server_context:)
      appropriations = Appropriation.of_year(budget_year).order(:purpose, :recipient)

      return answer("No appropriation has been set for #{budget_year}.") if appropriations.empty?

      answer(appropriations.map { |appropriation| describe(appropriation) }.join("\n"))
    end

    # One line per appropriation, amounts written as appropriated, charged and left
    def self.describe(appropriation)
      "#{appropriation.id}: #{appropriation.purpose} for #{appropriation.recipient}, " \
        "appropriated #{money(appropriation.amount)}, charged #{money(appropriation.charged)}, " \
        "left #{money(appropriation.balance)}"
    end
    private_class_method :describe

    # An amount with two decimals
    def self.money(amount) = format("%.2f", amount)
    private_class_method :money
  end
end
