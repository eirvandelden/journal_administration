json.extract! transaction, :id, :booked_at, :interest_at, :category_id, :note, :created_at, :updated_at
json.url transaction_url(transaction, format: :json)

json.mutations transaction.mutations do |mutation|
  json.extract! mutation, :id, :account_id, :amount
end
