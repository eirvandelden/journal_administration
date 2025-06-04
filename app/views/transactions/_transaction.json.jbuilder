json.extract! transaction, :id, :id, :from_account_id, :to_account_id, :amount, :booked_at, :interest_at, :category_id,
:note, :type, :created_at, :updated_at
json.url transaction_url(transaction, format: :json)
