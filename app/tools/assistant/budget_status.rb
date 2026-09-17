# Tells the assistant how the household is doing against its budget
module Assistant
  class BudgetStatus < Tool
    description "Compare what the budget planned for a period against what actually happened, " \
      "category by category. Covers the current month when no dates are given."
    annotations read_only_hint: true
    input_schema(
      properties: {
        start_date: { type: "string", description: "First day of the period, written as 2026-08-01" },
        end_date: { type: "string", description: "Last day of the period, written as 2026-08-31" }
      }
    )

    def self.call(server_context:, start_date: nil, end_date: nil)
      return problem(half_a_period) if [ start_date, end_date ].select(&:present?).one?
      return report(Dashboard.new) if start_date.blank? && end_date.blank?

      first_day = day(start_date)
      last_day = day(end_date)

      # An unreadable day must not quietly become the current month: the assistant would answer a
      # question nobody asked and have no way of noticing.
      return problem(unreadable(start_date, end_date)) if first_day.nil? || last_day.nil?
      return problem(backwards(first_day, last_day)) if last_day < first_day

      report(Dashboard.new(start_date: first_day, end_date: last_day))
    end

    def self.half_a_period
      "Give both days of the period, or neither for the current month. Write days as 2026-08-01."
    end
    private_class_method :half_a_period

    def self.unreadable(start_date, end_date)
      "Could not read #{start_date} to #{end_date} as a period. Write days as 2026-08-01."
    end
    private_class_method :unreadable

    def self.report(dashboard)
      return answer("No budget covers #{covering(dashboard)}.") if dashboard.active_budget.nil?

      planned = dashboard.budget_amounts

      return answer("The budget covering #{covering(dashboard)} has nothing planned.") if planned.empty?

      answer(planned.map { |category, amount| describe(category, amount, dashboard) }.join("\n"))
    end
    private_class_method :report

    def self.covering(dashboard)
      "#{dashboard.date_range.start_date.to_date} to #{dashboard.date_range.end_date.to_date}"
    end
    private_class_method :covering

    # Spending and earning are the same subtraction read from opposite sides, and an assistant
    # told that four thousand euro of salary was "spent" will pass that confusion on.
    def self.describe(category, planned, dashboard)
      net = dashboard.budget_actuals[category].to_f

      return earning(category, planned, -net) if category.credit?

      spending(category, planned, net)
    end
    private_class_method :describe

    def self.spending(category, planned, spent)
      remainder = planned - spent
      standing = remainder.negative? ? "#{money(-remainder)} over" : "#{money(remainder)} left"

      "#{category.name}: planned #{money(planned)}, spent #{money(spent)}, #{standing}"
    end
    private_class_method :spending

    def self.earning(category, expected, received)
      shortfall = expected - received
      standing = shortfall.positive? ? "#{money(shortfall)} still to come" : "#{money(-shortfall)} more than expected"

      "#{category.name}: expected #{money(expected)}, came in #{money(received)}, #{standing}"
    end
    private_class_method :earning

    def self.money(amount)
      format("%.2f", amount)
    end
    private_class_method :money
  end
end
