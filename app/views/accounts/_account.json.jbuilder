json.extract! account, :id, :name, :owner, :category_id, :created_at, :updated_at
json.account_numbers account.numbers
json.url account_url(account, format: :json)
