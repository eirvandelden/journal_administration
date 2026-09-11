# Lets an assistant change what a category may cost in a budget
module Assistant
  class SetBudgetAmount < Tool
    description "Set what one category may cost per month in a budget, replacing whatever was planned " \
      "for it before. Both the budget and the category are named by the numbers the other tools report."
    annotations idempotent_hint: true
    input_schema(
      properties: {
        budget_id: { type: "integer", description: "The number identifying the budget" },
        category_id: { type: "integer", description: "The number identifying the category to plan for" },
        amount: { type: "number", description: "What the category may cost per month" }
      },
      required: [ "budget_id", "category_id", "amount" ]
    )

    def self.call(budget_id:, category_id:, amount:, server_context:)
      budget = Budget.find_by(id: budget_id)
      return problem("No budget ##{budget_id} exists.") if budget.nil?

      # A person editing a finished budget in the app is correcting the record on purpose. An
      # assistant doing it in passing is rewriting history nobody asked it to touch.
      if budget.past?
        return problem("Budget ##{budget.id} already finished on #{budget.ends_at.to_date}, so an " \
          "assistant may not change it. Change it on the budgets page instead.")
      end

      category = Category.find_by(id: category_id)
      return problem("No category ##{category_id} exists.") if category.nil?

      plan(budget, category, amount)
    end

    def self.plan(budget, category, amount)
      planned = budget.plan(category: category, amount: amount)

      return problem(planned.errors.full_messages.to_sentence) if planned.errors.any?

      answer("#{category.name} may cost #{format("%.2f", planned.amount)} a month in the budget " \
        "starting #{budget.starts_at.to_date}.")
    end
    private_class_method :plan
  end
end
