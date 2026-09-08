# Lets an assistant start a new budget
module Assistant
  class StartBudget < Tool
    description "Start a budget running from a day, and optionally until another day. It can only " \
      "start today or later. Starting one closes whichever budget was running, the day before the " \
      "new one starts."
    input_schema(
      properties: {
        starts_on: { type: "string", description: "First day the budget runs, written as 2026-09-01" },
        ends_on: { type: "string", description: "Last day it runs; leave it out to run until further notice" }
      },
      required: [ "starts_on" ]
    )

    def self.call(starts_on:, server_context:, ends_on: nil)
      first_day = day(starts_on)
      return problem(unreadable(starts_on)) if first_day.nil?
      return problem(already_gone(first_day)) if first_day.past?

      if ends_on.present?
        last_day = day(ends_on)
        return problem(unreadable(ends_on)) if last_day.nil?
      end

      start(first_day, last_day)
    end

    # Starting a budget on a day gone by closes whatever was running then, and a budget that has
    # already finished is closed with its validations skipped. A person correcting the record on
    # the budgets page means to do that; an assistant asked for next month's budget does not.
    def self.already_gone(first_day)
      "A budget can only start today or later, and #{first_day} has passed. " \
        "Change a budget that has already run on the budgets page instead."
    end
    private_class_method :already_gone

    def self.unreadable(text)
      "Could not read #{text} as a day. Write days as 2026-09-01."
    end
    private_class_method :unreadable

    def self.start(first_day, last_day)
      budget = Budget.new(starts_at: first_day, ends_at: last_day)

      return problem(budget.errors.full_messages.to_sentence) unless budget.save

      answer([ describe(budget), closing(budget) ].compact.join(" "))
    end
    private_class_method :start

    def self.describe(budget)
      running = budget.ends_at.nil? ? "runs until further notice" : "runs to #{budget.ends_at.to_date}"

      "Budget ##{budget.id} starts #{budget.starts_at.to_date} and #{running}, with nothing planned yet."
    end
    private_class_method :describe

    # Starting a budget closes the one that was running, which is easy to do by accident and
    # impossible to notice unless the answer says so.
    def self.closing(budget)
      closed = budget.closed_predecessor

      return nil if closed.nil?

      "It closed budget ##{closed.id}, which now ends on #{closed.ends_at.to_date}."
    end
    private_class_method :closing
  end
end
