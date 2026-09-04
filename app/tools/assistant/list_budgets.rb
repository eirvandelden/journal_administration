# Tells the assistant which budgets exist and when each one runs
module Assistant
  class ListBudgets < Tool
    HIGHEST_COUNT = 100

    description "List the household budgets, newest first: when each one runs, whether it is the one " \
      "running now, and how many categories it plans for. At most #{HIGHEST_COUNT} are listed."
    annotations read_only_hint: true

    def self.call(server_context:)
      budgets = Budget.includes(:budget_categories).order(starts_at: :desc).limit(HIGHEST_COUNT)

      return answer("No budget has been set yet.") if budgets.empty?

      answer([ *budgets.map { |budget| describe(budget) }, held_back(budgets) ].compact.join("\n"))
    end

    def self.describe(budget)
      "#{budget.id}: #{period(budget)}, #{standing(budget)}, #{plan(budget)}"
    end
    private_class_method :describe

    def self.period(budget)
      return "#{budget.starts_at.to_date} onwards" if budget.ends_at.nil?

      "#{budget.starts_at.to_date} to #{budget.ends_at.to_date}"
    end
    private_class_method :period

    def self.standing(budget)
      return "running now" if budget.active?
      return "starts later" if budget.future?

      "finished"
    end
    private_class_method :standing

    def self.plan(budget)
      planned = budget.budget_categories.size

      return "nothing planned" if planned.zero?

      "#{planned} #{"category".pluralize(planned)} planned"
    end
    private_class_method :plan

    def self.held_back(budgets)
      total = Budget.count

      return nil if total <= budgets.length

      "Showing #{budgets.length} of #{total} budgets - the older ones are on the budgets page."
    end
    private_class_method :held_back
  end
end
