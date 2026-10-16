json.extract! account, :id, :name, :owner, :category_id, :created_at, :updated_at
json.owner_name account.owner_name
json.account_numbers account.numbers
json.url account_url(account, format: :json)
