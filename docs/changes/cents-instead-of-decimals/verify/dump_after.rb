# Run on the branch's code after the migration. Writes the same lines as dump_before.rb, from cents
# and every dashboard figure rendered with two decimals, for the twelve months
# up to the month of the newest transaction (the copied data ends in the past).
helpers = ApplicationController.helpers
COLUMNS = {
  Appropriation => [ :amount ], BudgetCategory => [ :amount ], Chattel => [ :purchase_price ],
  ReceiptLine => %i[full_amount discount_amount paid_amount], Receipt => [ :total_amount ],
  TransactionSplit => [ :amount ], Transaction => %i[amount original_balance_after_mutation]
}.freeze

COLUMNS.each do |model, columns|
  model.unscoped.order(:id).find_each do |record|
    columns.each do |column|
      value = record.public_send(column)
      puts [ model.table_name, column, record.id, value && format("%.2f", Cents.to_euros(value)) ].join(", ")
    end
  end
end

def name_of(category) = category&.name || "(none)"

latest = Transaction.maximum(:booked_at).to_date.beginning_of_month

12.times do |back|
  month = latest - back.months
  dashboard = Dashboard.new(start_date: month, end_date: month.end_of_month)
  puts "dashboard #{month}"
  puts "debit_total #{helpers.cents_to_currency(dashboard.debit_total)}"
  puts "credit_sub_total #{helpers.cents_to_currency(dashboard.credit_sub_total)}"
  puts "credit_total #{helpers.cents_to_currency(dashboard.credit_total)}"
  puts "profit_or_loss #{helpers.cents_to_currency(dashboard.profit_or_loss)}"
  dashboard.debit_transactions.each do |category, total|
    puts "debit #{name_of(category)} #{helpers.cents_to_currency(total)}"
  end
  dashboard.credit_transactions.each do |category, total|
    puts "credit #{name_of(category)} #{helpers.cents_to_currency(total)}"
  end
  dashboard.budget_amounts.each do |category, total|
    puts "budget_amount #{name_of(category)} #{helpers.cents_to_currency(total)}"
  end
  dashboard.chart_labels.zip(dashboard.historical_averages).each do |label, average|
    puts "historical_average #{label} #{helpers.cents_to_currency(average)}"
  end
end

Budget.order(:id).each do |budget|
  budget.budget_categories.order(:id).each do |allocation|
    puts "budget #{budget.id} #{name_of(allocation.category)} #{helpers.cents_to_currency(allocation.amount)}"
  end
end
