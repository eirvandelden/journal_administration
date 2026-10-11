json.extract! account, :id, :id, :account_number, :name, :owner, :category_id, :created_at, :updated_at
json.owner_name account.owner_name
json.url account_url(account, format: :json)
