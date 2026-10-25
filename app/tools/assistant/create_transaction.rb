# Lets an assistant book a transaction between two accounts
module Assistant
  class CreateTransaction < Tool
    description "Book a transaction from one account to another. Whether it is a debit, a credit or a " \
      "transfer follows from which accounts are ours. Accounts are named by the numbers find_accounts reports."
    input_schema(
      properties: {
        debitor_account_id: { type: "integer", description: "The account the money leaves" },
        creditor_account_id: { type: "integer", description: "The account the money goes to" },
        amount: { type: "number", description: "The amount in euros, at most two decimals, for example 12.50" },
        booked_on: { type: "string", description: "The day the bank booked it, written as 2026-08-01" },
        interest_on: { type: "string", description: "The day it counts for; the booking day when left out" },
        category_id: { type: "integer", description: "The category to file it under" },
        note: { type: "string", description: "A note to remember it by" }
      },
      required: [ "debitor_account_id", "creditor_account_id", "amount", "booked_on" ]
    )

    # Mirrors transactions#create
    def self.call(debitor_account_id:, creditor_account_id:, amount:, booked_on:, server_context:,
      interest_on: nil, category_id: nil, note: nil)
      cents = cents_from(amount)
      return problem(two_decimals) if cents.nil?

      booked, interest = day(booked_on), interest_on.present? ? day(interest_on) : day(booked_on)
      return problem("Write days as 2026-08-01.") if booked.nil? || interest.nil?

      accounts = Account.where(id: [ debitor_account_id, creditor_account_id ]).index_by(&:id)
      missing = [ debitor_account_id, creditor_account_id ].find { |id| accounts[id].nil? }
      return problem("No account ##{missing} exists.") if missing

      category = Category.find_by(id: category_id) if category_id
      return problem("No category ##{category_id} exists.") if category_id && category.nil?

      book(Transaction.new(debitor: accounts[debitor_account_id], creditor: accounts[creditor_account_id],
        amount: cents, booked_at: booked.beginning_of_day, interest_at: interest.beginning_of_day,
        category: category, note: note))
    end

    def self.book(transaction)
      return refusal(transaction) unless transaction.save

      answer("Booked #{transaction.type.downcase} ##{transaction.id} of #{euros(transaction.amount)}.")
    end
    private_class_method :book
  end
end
