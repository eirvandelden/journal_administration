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
      unless period(start_date, end_date)
        return problem("Could not read #{start_date} to #{end_date} as a period. Write dates as 2026-08-01.")
      end

      report(Dashboard.new(start_date: start_date, end_date: end_date))
    end

    # An unreadable date must not quietly become the current month: the assistant would answer a
    # question nobody asked and have no way of noticing.
    def self.period(start_date, end_date)
      return DateRange.from_filter(nil) if start_date.blank? && end_date.blank?
      return nil unless day(start_date) && day(end_date)

      DateRange.from_dates(start_date, end_date)
    end
    private_class_method :period

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
